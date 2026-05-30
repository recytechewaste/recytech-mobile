# RecyTech Simple System Architecture

## Overview

RecyTech is a web-based recycling management system with a React frontend, an Express.js REST API, and MongoDB for persistence. The system supports role-based access for Staff, Admin, Super Admin, and Collector users.

```mermaid
flowchart LR
    User[Web User / Staff / Admin / Super Admin] --> Frontend[React Frontend<br/>Vite + React Router]
    Frontend --> ApiClient[Axios API Client<br/>JWT Bearer Token]
    ApiClient --> Backend[Express.js API Server]

    Backend --> Auth[Auth Middleware<br/>JWT + Role Checks]
    Auth --> Routes[Feature Route Modules]

    Routes --> Models[Mongoose Models]
    Models --> DB[(MongoDB)]

    Routes --> Analytics[Analytics + Forecasting Utilities]
    Routes --> Payouts[Payout Calculation Utility]
    Routes --> Scheduling[Scheduling Utility]
```

## Main Components

### 1. Frontend Application

Location: `recytechfrontend/src`

The frontend is a Vite React app. It uses React Router for page navigation and a shared Axios client for backend communication.

Key frontend parts:

- `App.jsx` defines public and protected routes.
- `api/client.js` configures the backend API URL and attaches the JWT token from `localStorage`.
- `ProtectedRoute.jsx` controls access to authenticated pages and role-specific pages.
- Page modules include dashboard, reports, requests, residents, collectors, users, education, exchange rates, transactions, and settings.

### 2. Backend API

Location: `server.js` and `recytechbackend/routes`

The backend is an Express.js server. It loads environment variables, connects to MongoDB, enables CORS, parses JSON requests, and mounts feature-specific API routes.

Main API groups:

- `/api/auth` - login, registration, forgot password, PIN verification, password reset
- `/api/users` - Super Admin user management
- `/api/requests` - recycling pickup/request management
- `/api/residents` - resident profile and wallet management
- `/api/collectors` - collector management
- `/api/transactions` - payout and transaction history
- `/api/exchange-rates` - waste-type payout rates
- `/api/education` - educational content management
- `/api/analytics` - dashboard reports, trends, summaries, predictive analytics
- `/api/scheduling` - forecasting, recommendations, assignment confirmation
- `/api/recycling-centers` - recycling center records

### 3. Authentication and Authorization

Location: `recytechbackend/middleware/authMiddleware.js`

Authentication uses JSON Web Tokens. After login, the frontend stores user information and the token in `localStorage`. Each API request sends the token as:

```text
Authorization: Bearer <token>
```

Backend authorization levels:

- `protect` verifies the JWT and loads the current user.
- `admin` allows Admin and Super Admin users.
- `superAdmin` allows only Super Admin users.

### 4. Database Layer

Location: `recytechbackend/models`

The backend uses Mongoose models to read and write MongoDB data.

Core collections:

- `User` - staff/admin/super admin/collector login accounts
- `Resident` - recycling residents, wallet balance, earnings, request count
- `Collector` - collector profile, linked user account, vehicle information
- `Request` - recycling request details, status, assigned collector, payout data
- `Transaction` - resident payments, refunds, adjustments
- `ExchangeRate` - active payout rates by waste type
- `Education` - articles, videos, PDFs, thumbnails, publication status

## Main Data Flow

```mermaid
sequenceDiagram
    participant User as User
    participant UI as React Frontend
    participant API as Express API
    participant Auth as Auth Middleware
    participant DB as MongoDB

    User->>UI: Uses dashboard or management page
    UI->>API: Sends API request with JWT token
    API->>Auth: Validates token and role
    Auth-->>API: Allows request
    API->>DB: Reads or updates data through Mongoose
    DB-->>API: Returns persisted data
    API-->>UI: Sends JSON response
    UI-->>User: Updates page state
```

## Example Business Flow: Recycling Request to Payout

```mermaid
flowchart TD
    A[Create Recycling Request] --> B[Request stored as Pending]
    B --> C[Admin reviews request]
    C --> D{Approved?}
    D -- No --> E[Request marked Rejected]
    D -- Yes --> F[Assign collector and schedule pickup]
    F --> G[Request moves to In-Transit]
    G --> H[Request completed]
    H --> I[Calculate payout from exchange rate]
    I --> J[Create transaction]
    J --> K[Update resident wallet and earnings]
```

## Deployment Shape

```mermaid
flowchart TB
    Browser[Browser] --> ViteApp[React Static App]
    ViteApp --> Express[Node.js / Express Server]
    Express --> Mongo[(MongoDB Database)]

    Env[Environment Variables<br/>PORT, MONGO_URI, JWT_SECRET] --> Express
```

## Architecture Summary

RecyTech follows a simple three-layer architecture:

1. **Presentation layer** - React frontend pages and route protection.
2. **API/business layer** - Express route modules, authentication middleware, analytics, scheduling, and payout utilities.
3. **Data layer** - MongoDB accessed through Mongoose models.

This structure keeps the user interface, business rules, and database access separated while still being lightweight enough for a prototype.
