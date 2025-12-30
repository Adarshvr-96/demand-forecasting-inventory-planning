SELECT * FROM `ml-project-482013.saas_demand.raw_transactions` LIMIT 100


SELECT
  COUNT(*) AS negative_quantity_rows
FROM `saas_demand.raw_transactions`
WHERE Quantity < 0;


SELECT
  COUNT(*) AS zero_or_null_price
FROM `saas_demand.raw_transactions`
WHERE Price IS NULL OR Price <= 0;


CREATE OR REPLACE TABLE `saas_demand.clean_transactions` AS
SELECT
  Invoice,
  StockCode,
  Description,
  Quantity,
  InvoiceDate,
  Price,
  CAST(`Customer ID` AS INT64) AS customer_id,
  Country,
  Quantity * Price AS revenue
FROM `saas_demand.raw_transactions`
WHERE
  Quantity > 0
  AND Price > 0
  AND `Customer ID` IS NOT NULL;



CREATE OR REPLACE TABLE `saas_demand.clean_transactions` AS
SELECT
  Invoice,
  StockCode,
  Description,
  Quantity,
  InvoiceDate,
  Price,
  CAST(`Customer ID` AS INT64) AS customer_id,
  Country,
  Quantity * Price AS revenue
FROM `saas_demand.raw_transactions`
WHERE
  Quantity > 0
  AND Price > 0
  AND `Customer ID` IS NOT NULL;


--- Demand forecasting is time-series, so we extract dates.

CREATE OR REPLACE TABLE `saas_demand.transactions_time` AS
SELECT
  *,
  DATE(InvoiceDate) AS order_date,
  EXTRACT(YEAR FROM InvoiceDate) AS year,
  EXTRACT(MONTH FROM InvoiceDate) AS month
FROM `saas_demand.clean_transactions`


--- ML forecasts aggregated demand, not raw transactions.

CREATE OR REPLACE TABLE `saas_demand.daily_demand` AS
SELECT
  order_date,
  SUM(Quantity) AS total_units_sold,
  SUM(revenue) AS daily_revenue
FROM `saas_demand.transactions_time`
GROUP BY order_date
ORDER BY order_date


SELECT
  COUNT(*) AS rws,
  SUM(Quantity) AS net_quantity
FROM `saas_demand.raw_transactions`
WHERE Quantity < 0;


CREATE OR REPLACE TABLE `saas_demand.weekly_demand` AS
SELECT
  DATE_TRUNC(DATE(InvoiceDate), WEEK(MONDAY)) AS week_start,
  SUM(Quantity) AS weekly_units,
  ROUND(SUM(Quantity * Price), 2) AS weekly_revenue
FROM `saas_demand.clean_transactions`
GROUP BY week_start
ORDER BY week_start;


SELECT
  COUNT(*) AS total_weeks,
  MIN(week_start) AS first_week,
  MAX(week_start) AS last_week
FROM `saas_demand.weekly_demand`;

--- Understand demand behavoiur

select  
  week_start,
  weekly_units
from `saas_demand.weekly_demand`
order by week_start

--- 4-week rolling demand

select
  week_start,
  weekly_units,
  avg(weekly_units) over(order by week_start 
      rows between 3 preceding and current row ) as rolling_4w_demand
from `saas_demand.weekly_demand`
order by week_start

--- Seasonality check 

select 
    extract(month from week_start) as mnt,
    round(avg(weekly_units),2) as avg_weekly_units
from `saas_demand.weekly_demand`
group by mnt
order by mnt

--- demand varibility (voltality: Is ML forecasting appropriate or risky?

-- CV Value	Meaning
-- < 0.3	Very stable
-- 0.3–0.7	Moderate variability
-- > 0.7	Highly volatile (hard to forecast)

SELECT
  ROUND(AVG(weekly_units), 2) AS avg_demand,
  ROUND(STDDEV(weekly_units), 2) AS demand_volatility,
  ROUND(STDDEV(weekly_units) / AVG(weekly_units), 2) AS coeff_of_variation
FROM `saas_demand.weekly_demand`;

CREATE OR REPLACE TABLE `saas_demand.weekly_demand_trend` AS
SELECT
  week_start,
  weekly_units,
  AVG(weekly_units) OVER (
    ORDER BY week_start
    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
  ) AS rolling_4w_demand
FROM `saas_demand.weekly_demand`;



 --Week Ahead Baseline Forecast
--- Predict next week demand

CREATE OR REPLACE TABLE `saas_demand.weekly_baseline_forecast` AS
SELECT
  week_start,
  weekly_units,
  rolling_4w_demand AS baseline_forecast_next_week
FROM `saas_demand.weekly_demand_trend`
WHERE rolling_4w_demand IS NOT NULL;

select * from `saas_demand.weekly_baseline_forecast`

--- Measure Forecast Error (How good is baseline?)
  -- Now calculate forecast error metrics.

SELECT
  AVG(ABS(weekly_units - baseline_forecast_next_week)) AS mae,
  AVG(POW(weekly_units - baseline_forecast_next_week, 2)) AS mse,
  SQRT(AVG(POW(weekly_units - baseline_forecast_next_week, 2))) AS rmse
FROM `saas_demand.weekly_baseline_forecast`;


-- ans
---------------------------------------------------------------------
-- MAE — Mean Absolute Error
---------------------------------------------------------------------
 -- MAE = ~19,900 units
-- On average, your weekly forecast is off by ~19,900 units.

 --- Business meaning:
   -- Inventory planning will miss demand by ~20k units/week
   -- Warehouses must buffer stock to absorb this error

----------------------------------------------------------------------
-- MSE — Mean Squared Error
----------------------------------------------------------------------
 -- MSE = 830,429,217

-- Penalizes large errors heavily
  -- Used internally by models, not for business decisions

----------------------------------------------------------------------
-- RMSE — Root Mean Squared Error
----------------------------------------------------------------------
-- RMSE = ~28,817 units

  --- Typical large forecast miss is ~29k units

--- Business meaning:
-- In peak weeks (seasonality, promotions), error spikes
-- Stockouts or overstock risk increases

------------------------------------------------------------------------------
------------------------------------------------------------------------------

CREATE OR REPLACE TABLE `saas_demand.weekly_demand_ts` AS
SELECT
  week_start AS date,
  weekly_units AS demand
FROM `saas_demand.weekly_demand`
ORDER BY date;

select * from `saas_demand.weekly_demand_ts`

-- Train ARIMA_PLUS

CREATE OR REPLACE MODEL `saas_demand.weekly_demand_arima`
OPTIONS (
  model_type = 'ARIMA_PLUS',
  time_series_timestamp_col = 'date',
  time_series_data_col = 'demand',
  auto_arima = TRUE,
  data_frequency = 'WEEKLY',
  holiday_region = 'US'
) AS
SELECT
  date,
  demand
FROM `saas_demand.weekly_demand_ts`;


SELECT
  *
FROM ML.EVALUATE(
  MODEL `saas_demand.weekly_demand_arima`
);


 -- Forecast Next 8 Weeks

SELECT
  forecast_timestamp AS week_start,
  forecast_value AS predicted_units,
  prediction_interval_lower_bound,
  prediction_interval_upper_bound
FROM ML.FORECAST(
  MODEL `saas_demand.weekly_demand_arima`,
  STRUCT(8 AS horizon)
);

--- Predict next 8 weeks of demand 

CREATE OR REPLACE TABLE `saas_demand.weekly_forecast` AS
SELECT
  forecast_timestamp AS week_start,
  forecast_value AS forecast_units,
  prediction_interval_lower_bound AS lower_bound,
  prediction_interval_upper_bound AS upper_bound
FROM ML.FORECAST(
  MODEL `saas_demand.weekly_demand_arima`,
  STRUCT(8 AS horizon, 0.9 AS confidence_level)
);

 --— Convert Forecast into Inventory Plan
  --- Business logic:

 -- Stock to upper bound → avoid stockouts
 -- Stock to forecast → average case
 -- Lower bound → risk of overstock

SELECT
  week_start,
  ROUND(forecast_units) AS expected_units,
  ROUND(upper_bound) AS max_units_to_stock,
  ROUND(lower_bound) AS min_units
FROM `saas_demand.weekly_forecast`
ORDER BY week_start;


--- Revenue Projection

 --- Assume: Average price per unit = $12

SELECT
  week_start,
  forecast_units,
  forecast_units * 12 AS expected_revenue,
  upper_bound * 12 AS max_revenue
FROM `saas_demand.weekly_forecast`
ORDER BY week_start;


 ---  Risk Analysis (Stockout vs Overstock)
SELECT
  week_start,
  upper_bound - forecast_units AS safety_buffer_units,
  (upper_bound - forecast_units) * 12 AS buffer_cost
FROM `saas_demand.weekly_forecast`;





















































































































































































