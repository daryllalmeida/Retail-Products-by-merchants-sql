Catalog & Fulfillment KPI Deep Dive (SQL)

**Project overview**

This project analyzes order fulfillment and catalog availability to understand what drives poor customer experience (missing items, substitutions, and inventory problems. Using SQL, I computed core KPIs, drilled down by store brand × city, and surfaced operational root causes at the store and product level.

**Data used**

Tables explored:

orders_order (ordered vs found quantities, delivery timestamps)

catalog_productbranches (product availability + active flags at branch level)

catalog_storebranch, catalog_store (store and branch mapping)

geo_city (city dimension)

**Key KPIs**

Found Rate (items found / items ordered): 89.69%

Out-of-Stock % (active products): 3.50% | Available %: 96.48%

Delivered orders: 4,556 (no null actual_delivery_time)

Deep Dives

Broke down performance by store brand × city to surface low performers (e.g., some locations with materially lower Found Rate and higher OOS%).

Added an order-level metric: % Orders Fully Fulfilled (found = ordered) to reveal cases where Found Rate looks fine but customers still get incomplete orders.

Identified high-risk SKUs with frequent OOS and inconsistent availability patterns (suggesting stale merchant inventory feeds).

Outcome
Created a clear prioritization view for Ops: focus on store/city combos with low Found Rate, high OOS%, and low fully-fulfilled order %, plus top “risk SKUs” driving the most customer pain.
