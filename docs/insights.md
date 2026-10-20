# Insights and Recommendations

All numbers come from delivered orders only (96,478 orders, R$13,221,498.11 product revenue, freight excluded). Trend charts cover Jan 2017 to Aug 2018. Every figure below can be reproduced with the SQL files in `sql/` and appears in the Power BI dashboard.

## 1. Late delivery sharply lowers customer satisfaction

**Evidence**
- 6,534 orders (6.77%) were delivered after the estimated date and averaged a 2.27 review score, versus 4.29 for the 89,936 on-time or early orders.
- The score falls as the delay grows: 1-3 days late 3.29, 4-7 days late 2.10, 8+ days late 1.70.
- Orders that are 8+ days late are only 2.97% of orders but carry the worst experience.

**Recommendation**
- Treat "more than 3 days late" as an escalation threshold: proactive customer messaging and a fast refund or reship path, because the score drops by more than a full point once an order is 4+ days late.
- Review how the estimated delivery date is set. Padding estimates in slow regions would move late orders back to "on time" in the customer's eyes.

*Note: this is an association in observational data, not proof that lateness alone causes low scores.*

## 2. Almost no customers come back

**Evidence**
- 97.00% of customers (90,557 of 93,358) ordered once. Only 3.00% are repeat customers.
- Month-1 retention across all cohorts is 0.48%.
- Repeat customers generate just 5.51% of revenue, while one-time customers generate 94.49%.
- Champions (114 customers) spend R$490.16 on average, about 3.6 times the R$137.96 of a one-time customer.

**Recommendation**
- Retention is the biggest growth opportunity: a post-purchase email or coupon flow in the first 30 days, targeted at higher-value first-time buyers.
- Use the Champions and Big Spenders (1,991 customers, R$305.44 average spend) profile to choose which first-time buyers to prioritise.

## 3. Revenue is concentrated in a few categories and one state

**Evidence**
- Health & Beauty (9.33%), Watches & Gifts (8.82%) and Bed Bath & Table (7.74%) together are 25.89% of revenue.
- Sao Paulo alone is R$5,068,589.63, about 38% of revenue, from 40,500 orders. Sao Paulo, Rio de Janeiro and Minas Gerais together are about 63%.
- Monthly revenue peaked at R$987,765.37 in Nov 2017 and was R$838,576.64 in Aug 2018.

**Recommendation**
- Keep inventory and marketing focus on the leading categories, but test growth outside Sao Paulo, where marketplace dependence on one state is a risk.

## 4. Delivery is much slower outside the south-east

**Evidence**
- Average delivery time is 8.70 days in Sao Paulo versus 29.34 in Roraima, 27.18 in Amapa and 26.36 in Amazonas. The overall average is 12.41 days.
- Sao Paulo holds about 42% of delivered orders, so the national average hides the slow states.

**Recommendation**
- For northern states, set longer and honest delivery promises, add a regional carrier or fulfilment partner, and onboard local sellers where volume justifies it.

## 5. A small group of sellers drives poor service

**Evidence**
- Among sellers with 30+ delivered orders, five have late-delivery rates above 26% (the top is 32.56%, 14 of 43 orders), against 6.77% overall.
- The lowest-rated seller with 30+ reviewed orders scores 2.39 across 107 orders. A Campinas seller scores 2.79 across 184 orders with only 10.87% late, so lateness is not the only cause of poor reviews.
- Among large categories, Bed Bath & Table is the weakest-rated (4.00 on R$1.02M revenue, versus 4.16 overall), and Office Furniture scores 3.64 on R$268,154.

**Recommendation**
- Introduce a seller scorecard (late %, review score, orders) with a support-or-penalty process for sellers below agreed thresholds.
- Investigate quality in Bed Bath & Table and Office Furniture before scaling them further.

*Note: seller rates are based on small order counts (30 to 100), so treat them as a watch list, not a verdict.*
