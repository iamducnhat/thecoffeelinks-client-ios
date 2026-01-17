# API Requirements - Features Needing Backend Support

This document outlines features from the UX research that require new or modified backend APIs.

## Base URL
`https://server-nu-three-90.vercel.app/`

---

## 1. LinkedIn Authentication

**Status**: ❌ Not Implemented  
**Priority**: P0 (Critical for MVP per user)

### Required Endpoint

```
POST /api/auth/linkedin
```

**Request**:
```json
{
  "code": "linkedin_auth_code",
  "redirect_uri": "https://app.thecoffeelinks.com/auth/callback"
}
```

**Response**:
```json
{
  "success": true,
  "session": {
    "access_token": "...",
    "refresh_token": "...",
    "expires_at": "...",
    "user": {
      "id": "uuid",
      "email": "user@company.com",
      "full_name": "Full Name",
      "headline": "Product Manager @ Company",
      "avatar_url": "https://linkedin.com/...",
      "linkedin_profile": "https://linkedin.com/in/username"
    }
  }
}
```

---

## 2. User Profile Enhancements

**Status**: ⚠️ Partial (missing professional fields)  
**Priority**: P0

### Modify Existing Endpoint

```
PUT /api/users/me
```

**Add these fields to request/response**:
```json
{
  "headline": "Senior Developer @ StartupX",
  "job_title": "Senior Developer",
  "company": "StartupX",
  "industry": "Technology",
  "bio": "Coffee enthusiast and code lover",
  "linkedin_url": "https://linkedin.com/in/username",
  "is_open_to_networking": true,
  "networking_intent": "learning"
}
```

---

## 3. Networking Intent System

**Status**: ❌ Not Implemented  
**Priority**: P0

### New Field in Check-In

```
POST /api/presence/check-in
```

**Add to request**:
```json
{
  "store_id": "uuid",
  "mode": "open",
  "intent": "hiring",
  "table_number": "7"
}
```

**Intent values**: `hiring`, `learning`, `collaboration`, `open_chat`

### People Discovery Enhancement

```
GET /api/presence?store_id={id}&intent={intent}
```

**Response should include user's intent**:
```json
{
  "users": [
    {
      "id": "uuid",
      "full_name": "...",
      "headline": "...",
      "intent": "learning",
      "mode": "open",
      "table_number": "5",
      "entered_at": "..."
    }
  ]
}
```

---

## 4. Favorite Notes

**Status**: ⚠️ Partial (favorites exist, notes don't)  
**Priority**: P1

### Modify Favorites

```
POST /api/favorites
PUT /api/favorites/{id}
```

**Add notes field**:
```json
{
  "product_id": "uuid",
  "customization": { ... },
  "notes": [
    "Extra hot",
    "Order on Mondays",
    "For meetings"
  ]
}
```

**Validation**:
- Max 3 notes per favorite
- Max 140 characters per note

---

## 5. AI Prediction Data

**Status**: ❌ Not Implemented  
**Priority**: P2 (can be client-side initially)

### Optional Server-Side Enhancement

```
GET /api/predictions/order?time={time}&day={day}&weather={weather}
```

**Response**:
```json
{
  "success": true,
  "prediction": {
    "confidence": 0.85,
    "items": [
      {
        "product_id": "uuid",
        "quantity": 1,
        "size": "medium",
        "reasoning": "You usually order this on Monday mornings"
      }
    ],
    "estimated_total": 55000
  }
}
```

**Note**: If not implemented, client will do local prediction using order history.

---

## 6. Time-Boxed Check-In

**Status**: ⚠️ Backend supports check-in but not auto-expiry  
**Priority**: P1

### Modify Check-In

```
POST /api/presence/check-in
```

**Add duration field**:
```json
{
  "store_id": "uuid",
  "mode": "open",
  "duration_minutes": 60
}
```

**Response should include**:
```json
{
  "check_in": {
    "id": "uuid",
    "expires_at": "2026-01-16T02:00:00Z"
  }
}
```

**Backend should**:
- Auto check-out user after duration expires
- Cron job or scheduled task to clean up expired check-ins

---

## 7. Trust Badges & Social Proof

**Status**: ❌ Not Implemented  
**Priority**: P2

### Add to User Profile Response

```
GET /api/users/{id}
```

**Add computed fields**:
```json
{
  "trust_stats": {
    "total_connections": 25,
    "meetings_completed": 12,
    "recommended_by_count": 5,
    "positive_review_rate": 0.92,
    "badges": ["verified_networker", "recommended"]
  }
}
```

**Badge logic**:
- `verified_networker`: connections >= 5
- `recommended`: recommended_by_count >= 3
- `highly_rated`: positive_review_rate >= 0.9
- `new_to_networking`: meetings_completed < 3

---

## 8. Community Posts (4 Types)

**Status**: ⚠️ Backend has /api/social/posts but not typed  
**Priority**: P1

### Modify Posts

```
POST /api/social/posts
```

**Enforce type field**:
```json
{
  "type": "hiring",
  "content": "Looking for a junior developer for my startup"
}
```

**Valid types**: `hiring`, `learning`, `collaboration`, `event_discussion`

**Validation**:
- Type must be one of 4 allowed values
- Content max 280 characters
- No free-form generic posts

---

## 9. Weather-Reactive Menu

**Status**: ❌ Not Implemented  
**Priority**: P2 (nice-to-have)

### Optional Enhancement

```
GET /api/menu?weather={condition}&temp={celsius}
```

**Response includes weather badges**:
```json
{
  "products": [
    {
      "id": "...",
      "name": "Hot Chocolate",
      "weather_badge": "warm_up"
    }
  ]
}
```

**Note**: Can be done client-side with WeatherKit.

---

## 10. Table/Room Booking (Replace Space Tab)

**Status**: ❌ Not Needed (user confirmed: replace with Dine-In)  
**Priority**: Cancelled

**Solution**: Use existing dine-in flow with table number input.

---

## Summary Table

| Feature | Backend Status | Priority | Workaround |
|---------|---------------|----------|-----------|
| LinkedIn Auth | ❌ Missing | P0 | Use Apple/Google for now, add LinkedIn later |
| Professional Profile Fields | ⚠️ Partial | P0 | Use `bio` field for headline temporarily |
| Networking Intents | ❌ Missing | P0 | Store client-side, filter locally |
| Favorite Notes | ⚠️ Partial | P1 | Store notes in `customization` JSON |
| AI Predictions | ❌ Missing | P2 | Do all prediction client-side |
| Time-Boxed Check-In | ⚠️ Partial | P1 | Client-side timer + manual check-out |
| Trust Badges | ❌ Missing | P2 | Calculate client-side from connections |
| Typed Community Posts | ⚠️ Partial | P1 | Enforce types client-side |
| Weather-Reactive | ❌ Missing | P2 | Use iOS WeatherKit API |
| Space Booking | Cancelled | N/A | Use Dine-In instead |

---

## Client-Side Workarounds

For features not yet in backend, the iOS app will:

1. **LinkedIn**: Use Apple/Google auth, add LinkedIn in future update
2. **Intents**: Store in `UserDefaults`, include in profile `bio` field as hashtag
3. **Favorite Notes**: Store in local `UserDefaults` alongside favorite IDs
4. **AI Predictions**: Use local ML with order history from `/api/user/orders`
5. **Trust Badges**: Calculate from connection count via `/api/connections`
6. **Time-Boxed Check-In**: Set local timer, auto check-out client-side
7. **Weather**: Use Apple WeatherKit, adjust UI client-side

---

## Implementation Timeline

**Phase 1 (MVP)**:
- Use workarounds for all missing features
- App fully functional with available APIs
- Request backend team to implement P0 items

**Phase 2 (Enhanced)**:
- Integrate LinkedIn auth when available
- Switch from client-side to server-side predictions
- Add server-driven trust badges

**Phase 3 (Polished)**:
- Weather-reactive menu from backend
- Meeting reviews system
- Advanced analytics
