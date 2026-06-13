# webx

A new Flutter project.

graph TD
    A[Flutter Mobile Client] <-->|HTTPS / REST API| B[Django REST Backend \n hosted on Render]
    B <-->|Postgres Connection| C[Supabase PostgreSQL \n Database]
    D[GitHub Hosted JSONs] -->|HTTP GET| A
    style A fill:#4385F4,stroke:#333,stroke-width:2px,color:#fff
    style B fill:#092E20,stroke:#333,stroke-width:2px,color:#fff
    style C fill:#3ECF8E,stroke:#333,stroke-width:2px,color:#fff
