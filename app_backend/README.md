# Book Haven - FastAPI Backend

Modern, clean-architecture REST API backend built with FastAPI, SQLAlchemy, and Pydantic for the Online Book Library application.

---

## Architecture Overview

```
app_backend/
├── core/                  # Configuration, database engine, and security utilities
│   ├── __init__.py
│   ├── config.py          # Pydantic Settings and environment configuration
│   ├── database.py        # SQLAlchemy engine, session maker, and get_db dependency
│   └── security.py        # Password hashing (bcrypt) and JWT token generation/verification
│
├── models/                # SQLAlchemy database models (tables)
│   ├── __init__.py
│   ├── user.py            # User model
│   └── book.py            # Book and FavoriteBook models
│
├── schemas/               # Pydantic validation and serialization models
│   ├── __init__.py
│   ├── user.py            # UserCreate, UserLogin, UserResponse, Token schemas
│   └── book.py            # BookCreate, BookResponse, CategoryResponse schemas
│
├── services/              # Business logic and database operations layer
│   ├── __init__.py
│   ├── user_service.py    # User creation, authentication, profile updates
│   └── book_service.py    # Book querying, search, categories, favorites
│
├── routes/                # FastAPI API endpoints and routers
│   ├── __init__.py        # Aggregator combining all sub-routers under /api/v1
│   ├── deps.py            # Reusable route dependencies (get_current_user)
│   ├── auth.py            # /api/v1/auth (register, login, me)
│   ├── books.py           # /api/v1/books (catalog, search, categories, favorites)
│   └── users.py           # /api/v1/users (user listings and profile updates)
│
├── main.py                # Application entry point, lifespan, CORS, and root endpoints
├── requirements.txt       # Project dependencies
├── .env.example           # Example environment variables
├── .gitignore             # Python and virtual environment exclusions
└── README.md              # Documentation and guide
```

---

## Getting Started

### 1. Create a Virtual Environment

Open PowerShell or your preferred terminal inside the `app_backend` directory:

```powershell
cd "c:\Users\adage\Desktop\Library App\library_app\app_backend"

# Create a virtual environment
python -m venv venv

# Activate on Windows (PowerShell)
.\venv\Scripts\Activate.ps1

# (Or in Command Prompt)
.\venv\Scripts\activate.bat
```

### 2. Install Dependencies

```powershell
pip install -r requirements.txt
```

### 3. Configure Environment Variables (Optional)

Copy `.env.example` to `.env`:

```powershell
copy .env.example .env
```

### 4. Run the Development Server

```powershell
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

The server will automatically start on `http://127.0.0.1:8000`. Database tables and initial sample books are seeded automatically on first startup.

---

## Interactive API Documentation

Once the server is running, explore and test the endpoints directly in your browser:

- **Swagger UI**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **ReDoc**: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

---

## API Endpoints Summary

### Authentication (`/api/v1/auth`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Register a new user and receive JWT token | No |
| `POST` | `/api/v1/auth/login` | Log in with email & password | No |
| `GET` | `/api/v1/auth/me` | Get profile of currently logged-in user | Yes (Bearer) |

### Books & Library (`/api/v1/books`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/v1/books` | List books (supports `query` and `category` filters) | Optional |
| `GET` | `/api/v1/books/categories` | List categories with book counts and icons | No |
| `GET` | `/api/v1/books/favorites` | Get all favorite books of current user | Yes (Bearer) |
| `GET` | `/api/v1/books/{id}` | Get book details and full reading content | Optional |
| `POST` | `/api/v1/books` | Add a new book | Yes (Bearer) |
| `PUT` | `/api/v1/books/{id}` | Update existing book details | Yes (Bearer) |
| `DELETE` | `/api/v1/books/{id}` | Delete a book | Yes (Bearer) |
| `POST` | `/api/v1/books/{id}/favorite` | Toggle book favorite status | Yes (Bearer) |

### Users (`/api/v1/users`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/v1/users` | List registered users | Yes (Bearer) |
| `GET` | `/api/v1/users/{id}` | Get user by ID | Yes (Bearer) |
| `PUT` | `/api/v1/users/me` | Update current user's profile | Yes (Bearer) |
