# Thinking in Events: Building a Real-time CDC Pipeline with Ballerina

Imagine you’re running a fast-growing e-commerce platform. Thousands of orders are flying in every minute. Your marketing team wants to know the top-selling categories *right now* to adjust their ad spend. Your inventory system needs to reflect stock changes *instantly* across all regions.

In the old days, we’d wait for a nightly ETL (Extract, Transform, Load) job to churn through the database and spit out a report. But in today’s "now or never" economy, yesterday’s data is just a history lesson. We need to react to changes as they happen.

This is where **Change Data Capture (CDC)** enters the scene. Instead of asking the database "What has changed since I last checked?" (polling), we listen to the database’s own heartbeat—its transaction logs—and treat every insert, update, or delete as an event.

In this post, we’ll explore how to build a production-grade CDC pipeline using **Ballerina**, **MySQL**, **Kafka**, and **Redis**.

---

## The Architecture: A Symphony of Events

Our goal is to build a real-time analytics pipeline that captures e-commerce transactions and aggregates sales data. Here’s the high-level flow of our `cdc-pipeline` project:

1.  **The Source**: A MySQL database where our `products`, `orders`, and `order_items` live.
2.  **CDC Ingestion**: A Ballerina service that uses the Debezium engine to tail the MySQL binary log (binlog) and publish changes to Kafka.
3.  **The Backbone**: Apache Kafka, acting as our reliable event bus with topics for each data type.
4.  **Enrichment & Processing**: A consumer service that:
    *   Caches product and order metadata in **Redis**.
    *   Enriches incoming `order_item` events with that cached data.
    *   Aggregates sales by merchant and category.
5.  **The Sink**: A separate MySQL database for aggregated analytics.
6.  **The API**: A RESTful service to serve these insights to the world.

![CDC Pipeline Architecture](_resources/consolidated-services.png)
*Figure 1: The consolidated architecture of our CDC pipeline.*

---

## Step 1: Listening to the Database Heartbeat

The first challenge in any CDC system is getting the data out without putting a massive load on the source database. Traditional polling (e.g., `SELECT * FROM orders WHERE updated_at > ?`) is expensive and misses intermediate changes (like an order being created and then cancelled within the same polling interval).

Our `data_ingestion_svc` solves this by using the **Ballerina CDC connector**. Under the hood, it leverages Debezium to read the MySQL binlog. This is non-intrusive—the database simply treats our service as another "replica."

```ballerina
// Snippet of the CDC listener configuration
cdc:MySqlListenerConfiguration config = {
    host: "mysql-source",
    port: 3306,
    username: "debezium",
    password: "dbz",
    serverName: "ecommerce-server",
    database: "ecommerce_db",
    includeTables: ["ecommerce_db.products", "ecommerce_db.orders", "ecommerce_db.order_items"]
};
```

Whenever a row changes, Debezium produces a rich event containing the "before" and "after" state, which we then push into Kafka topics like `cdc-orders` and `cdc-products`.

---

## Step 2: The Art of Enrichment

Events in isolation are often "thin." An `order_item` event tells us a product was bought, but it might only contain a `product_id`. To calculate sales by *category*, we need the product’s category name. 

We *could* query the source database for every event, but that would defeat the purpose of a decoupled, high-performance pipeline. Instead, we use a **Cache-Aside** pattern with **Redis**.

Our `kafka_consumer_svc` does double duty:
1.  It listens to `cdc-products` and `cdc-orders` to keep a "look-aside" cache in Redis up to date.
2.  When an `order_item` arrives, it "enriches" the event by looking up the merchant and category from Redis.

---

## Step 3: Aggregation and Persistence

Once we have an enriched event (an order item with its price, category, and merchant info), we can perform real-time aggregation. We compute total sales and order counts, then persist them into our **Analytics Sink**.

The beauty of this separation is that our **Sink** database is optimized for *reads* (analytics), while our **Source** database remains optimized for *writes* (transactions).

---

## Beyond the Prototype: Making it Production-Ready

While setting up a CDC pipeline on your local machine is one thing, running it in production—where networks fail, databases restart, and traffic spikes occur—is a completely different beast. 

As Gayan Dassanayake points out in his excellent [article on production-ready Debezium](https://medium.com/@g.c.dassanayake/production-ready-debezium-5-production-problems-and-how-wso2-integrator-solves-them-63943c9b86d2), there are five critical hurdles you’ll face. Here’s how the Ballerina CDC connector helps us jump over them:

1.  **Health Monitoring**: In a containerized world (like Kubernetes), the orchestrator needs to know if your CDC engine is "alive" and "ready." Ballerina’s `cdc:isLive` and `cdc:isReady` functions, coupled with internal heartbeats, make it easy to expose standard liveness and readiness probes.
2.  **Connection Resilience**: Databases aren't always there when you need them. The connector features built-in, configurable exponential backoff and retry mechanisms, ensuring that transient network blips don't crash your entire pipeline.
3.  **State Persistence**: If your service restarts, it needs to know exactly where it left off in the binlog. Ballerina allows us to store offsets and schema history in Kafka topics, providing durable, distributed state management.
4.  **Throughput Tuning**: High-volume systems require fine-grained control. We can tune `maxBatchSize` and `pollInterval` directly in our Ballerina configuration to balance latency against throughput.
5.  **Smart Snapshotting**: Sometimes you need a full initial dump of the data; other times, you only want new changes. The connector supports flexible snapshot modes (like `INITIAL` or `SCHEMA_ONLY`) to suit your specific migration or synchronization needs.

---

## The "No Free Lunch" Principle

As we often say in system design, there is no such thing as a free lunch. Moving to an event-driven CDC pipeline brings its own set of challenges:

*   **Ordering Matters**: If a product is updated and then deleted, we must process those events in that exact order. Kafka’s partition-key strategy helps us here.
*   **Eventual Consistency**: There is a small lag between a change in the source and its appearance in the analytics API. For most business cases, this sub-second delay is perfectly acceptable, but it's a shift from the immediate consistency of a single database.
*   **Operational Complexity**: You’re now managing Kafka, Redis, and multiple services instead of one "monolithic" database.

---

## Wrapping Up: Thinking in Events

Building a CDC pipeline isn't just about moving data; it's about shifting our mindset. It's about moving from a world of "static state" to a world of "continuous flow."

By using Ballerina's first-class support for cloud-native protocols and connectors, we've built a robust, scalable system that can keep up with the demands of modern business.

If you’re curious to see the full implementation, check out the repository below and try running it yourself!

**Stay curious, and keep building.**

---

### Resources & References
*   [Full Project Source Code (GitHub)](https://github.com/ayeshLK/cdc-pipeline)
*   [Production-Ready Debezium: 5 Production Problems and How WSO2 Integrator Solves Them](https://medium.com/@g.c.dassanayake/production-ready-debezium-5-production-problems-and-how-wso2-integrator-solves-them-63943c9b86d2)
*   [Ballerina CDC Connector Documentation](https://lib.ballerina.io/ballerinax/cdc/latest)
*   [Debezium: Modern CDC for Databases](https://debezium.io/)
*   [Redpanda/Kafka: The Event Streaming Backbone](https://redpanda.com/)

---
*If you enjoyed this, you might also like my previous posts on [Thinking in Events](https://ayesh9303.medium.com/thinking-in-events-c84cd1c31a50) and [Learning WebSub](https://ayesh9303.medium.com/learning-websub-part-1-introduction-to-websub-94ee99a09a70).*
