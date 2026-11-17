# Limitations and Next Steps

The analysis is descriptive. It measures associations in historical data, not
causal effects, and every figure depends on the definitions below.

## 1. Scope of the revenue measure

- Revenue is the sum of item `price` for **delivered** orders only. Freight is
  excluded, so the totals are product revenue rather than gross merchandise
  value or take rate.
- Payments are not joined to items because 2,961 orders have more than one
  payment row. Joining payments would double count revenue.
- Canceled, unavailable, invoiced and shipped orders are excluded from the
  fact table, so fulfillment failures are invisible in the revenue and review
  analysis.

## 2. Customer identity and retention

- `customer_id` is unique per order, so retention and RFM use
  `customer_unique_id`. This is an approximation: the dataset has no account
  ID, and the same person could appear under more than one unique ID.
- 97.00% of 93,358 customers placed exactly one delivered order. Any
  month-1 to month-12 retention rate is therefore computed on a very small
  repeat base and should not be read as a stable cohort curve.
- The observation window ends in October 2018, and delivered orders end in
  August 2018. Cohorts from 2016 and from the last months of 2018 are too
  small or too short to interpret, so trend charts and cohorts use
  January 2017 to August 2018.

## 3. Delivery and review measures

- Late delivery means the delivered date (date part) is later than the
  estimated date. The estimate is not a promise, and padding it would move
  orders to "on time" without improving the customer experience.
- Eight delivered orders have no delivery date; their delay fields are `NULL`
  and they are excluded from late-delivery rates.
- Review scores are voluntary and may be missing or biased. Reviews have
  99,224 rows and 98,410 distinct `review_id`s, so the key is
  `(review_id, order_id)`; where an order has several reviews, the latest is
  used. 547 orders have more than one review.
- The drop from 4.29 to 2.27 is an association. Late orders may differ from
  on-time orders in ways the data does not record (region, seller, product).

## 4. Seller and category comparisons

- Seller late rates are shown only for sellers with 30 or more orders to limit
  small-sample noise. Even at that threshold a single month can move a rate by
  several percentage points.
- Category results mix products with different margins and delivery profiles.
  They identify where to investigate, not what caused the result.

## 5. Dashboard and exports

- Power BI Desktop is Windows-only. The `.pbix` cannot be rebuilt or refreshed
  in this Linux environment, so the committed PDF is a snapshot and the
  dashboard is not re-tested by CI.
- CI validates the committed CSV exports, not the report visuals. If the
  `.pbix` is refreshed, check the page totals against `exports/` and
  `docs/insights.md`.
- The export order is deterministic (sorted by key) so repeated exports are
  byte-identical. Power BI does not depend on row order.

## 6. What would strengthen the analysis

- A randomized or quasi-experimental test of delivery promises and retention
  interventions, rather than more slicing of the same observational data.
- Longer history to separate cohort effects from seasonality.
- Payment, freight and margin data joined at order level (without duplicating
  item rows) to move from revenue to profitability.
- Query-plan evidence (`EXPLAIN ANALYZE`) and indexes on the join keys if the
  models are run on larger data.
