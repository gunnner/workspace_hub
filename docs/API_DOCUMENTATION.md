# API Documentation

This project uses [Swagger/OpenAPI](https://swagger.io/) for interactive API documentation.

## 🚀 Quick Start

### Access the API Documentation

Open your browser and navigate to:
```
http://localhost:3000/api-docs
```

You'll see an interactive API documentation interface where you can:
- Browse all available endpoints
- Test API calls directly from your browser
- Copy ready-to-use curl commands
- View request/response schemas

---

## 🔐 Authentication

All API endpoints require Bearer token authentication.

### Get Your API Token

**Using Rails Console:**
```bash
docker-compose exec web rails console
```
```ruby
# Find or create a user
user = User.find_by(email: 'your@email.com')

# Get the API token
user.api_token
# => "your-api-token-here"

exit
```

### Authorize in Swagger UI

1. Click the **"Authorize"** button (green lock icon at the top right)
2. Paste your API token (without "Bearer" prefix)
3. Click **"Authorize"**
4. Click **"Close"**

Now all your API calls will be authenticated! ✅

---

## 🏢 Multi-Tenant Architecture

This API uses subdomain-based multi-tenancy. Each organization has its own subdomain.

### Setting the Organization

Each API request requires a `Host` header with your organization's subdomain:
```
Host: {your-organization}.localhost
```

**Example:**
```bash
curl -X GET "http://myorg.localhost:3000/api/v1/projects" \
  -H "Authorization: Bearer your-token-here" \
  -H "Host: myorg.localhost"
```

In Swagger UI, the `Host` parameter is automatically included in all endpoints.

### Test Organization

For testing purposes, a demo organization is available:
- **Subdomain:** `umbrella`
- **Full URL:** `http://umbrella.localhost:3000`

---

## 📚 Available Endpoints

### Projects API

Manage projects within your organization.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/projects` | List all projects |
| `POST` | `/api/v1/projects` | Create a new project |
| `GET` | `/api/v1/projects/{id}` | Get project details |
| `PATCH` | `/api/v1/projects/{id}` | Update a project |
| `DELETE` | `/api/v1/projects/{id}` | Delete a project |

### Tasks API

Manage tasks within projects.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/projects/{project_id}/tasks` | List all tasks in a project |
| `POST` | `/api/v1/projects/{project_id}/tasks` | Create a new task |
| `GET` | `/api/v1/projects/{project_id}/tasks/{id}` | Get task details |
| `PATCH` | `/api/v1/projects/{project_id}/tasks/{id}` | Update a task |
| `DELETE` | `/api/v1/projects/{project_id}/tasks/{id}` | Delete a task |

---

## 🔑 Authorization & Permissions

The API uses role-based access control (RBAC) with four roles:

### Role Hierarchy

| Role | Projects | Tasks | Description |
|------|----------|-------|-------------|
| **Owner** | Full access | Full access | Complete control over organization |
| **Admin** | Full access | Full access | Manage all resources except billing |
| **Member** | Create & edit own | Full access | Standard team member |
| **Viewer** | Read only | Read only | View-only access |

### Detailed Permissions

#### Owner
- ✅ All CRUD operations on projects and tasks
- ✅ Manage team members
- ✅ Change organization settings
- ✅ Manage billing and subscriptions
- ✅ Delete organization

#### Admin
- ✅ All CRUD operations on projects and tasks
- ✅ Manage team members
- ✅ View organization settings
- ❌ Cannot manage billing
- ❌ Cannot delete organization

#### Member
- ✅ Create projects
- ✅ Update and delete own projects
- ✅ View all projects
- ✅ Full CRUD on all tasks
- ❌ Cannot manage other members' projects
- ❌ Cannot manage team

#### Viewer
- ✅ View all projects
- ✅ View all tasks
- ❌ Cannot create, update, or delete anything

---

## 🧪 Testing the API

### Method 1: Swagger UI (Recommended)

1. Open http://localhost:3000/api-docs
2. Click "Authorize" and enter your token
3. Select any endpoint
4. Click "Try it out"
5. Modify parameters if needed
6. Click "Execute"
7. View the response

**Benefits:**
- Interactive interface
- No additional tools needed
- See all endpoints at once
- Auto-generated curl commands

### Method 2: curl

Copy curl commands from Swagger UI or use the examples above.

### Method 3: Postman/Insomnia

1. Import OpenAPI spec from: http://localhost:3000/api-docs/v1/swagger.yaml
2. Set up environment variables:
   - `base_url`: `http://umbrella.localhost:3000`
   - `api_token`: your token
3. Configure headers:
   - `Authorization`: `Bearer {{api_token}}`
   - `Host`: `umbrella.localhost`

---

## 🔧 Development

### Running Tests

Test the API endpoints:
```bash
# Run all tests
docker-compose exec web rspec

### Regenerating Documentation

After making changes to swagger specs:
```bash
# Regenerate swagger.yaml
docker-compose exec web rails rswag:specs:swaggerize

# Restart server to load new documentation
docker-compose restart web
```

### Adding New Endpoints

1. Create the controller in `app/controllers/api/v1/`
2. Add routes to `config/routes.rb`
3. Create swagger spec in `spec/requests/api/v1/*_swagger_spec.rb`
4. Run the spec to verify it works
5. Regenerate documentation
6. Restart server

---


- [OpenAPI Specification](https://swagger.io/specification/)
- [Rswag Documentation](https://github.com/rswag/rswag)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)

---
