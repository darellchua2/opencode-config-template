# Plan: Add JIRA Access Token Auto-Refresh Capability

## Issue Reference
- **Number**: #107
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/107
- **Labels**: `enhancement`

## Overview
Implement auto-refresh functionality for JIRA OAuth2 access tokens to prevent workflow interruptions caused by token expiration during active sessions.

## Acceptance Criteria
- [ ] Tokens refresh automatically before expiring (no user intervention required during normal use)
- [ ] Token expiration is proactively detected before API calls fail
- [ ] Proper error handling and user notification when refresh fails (e.g., refresh token expired)
- [ ] Token state (access token, refresh token, expiration) is tracked and managed correctly
- [ ] Documentation of refresh behavior is added to project docs
- [ ] No regression in existing JIRA OAuth2 authentication workflow

## Scope
- JIRA OAuth2 authentication layer
- Token storage and state management
- API request interceptors/middleware
- Error handling and user notifications
- Configuration and documentation

---

## Implementation Phases

### Phase 1: Research & Analysis
- [ ] Review JIRA Cloud OAuth 2.0 documentation for token lifecycle
- [ ] Determine if current OAuth2 grant type provides refresh tokens
- [ ] Identify default token TTL and configuration options
- [ ] Analyze existing JIRA authentication implementation in codebase
- [ ] Identify all code paths that make JIRA API calls

### Phase 2: Token State Management
- [ ] Design token storage schema (access_token, refresh_token, expires_at)
- [ ] Implement secure token storage mechanism
- [ ] Create token state manager with validity checking
- [ ] Add token metadata tracking (creation time, expiration time)

### Phase 3: Refresh Token Flow
- [ ] Implement OAuth2 refresh token grant (`grant_type=refresh_token`)
- [ ] Ensure initial authorization flow captures and persists refresh token
- [ ] Create refresh token API integration with JIRA
- [ ] Implement proactive refresh strategy (refresh when <5 min remaining)

### Phase 4: API Request Layer
- [ ] Create middleware/interceptor to check token validity before API calls
- [ ] Implement automatic token refresh on 401 responses
- [ ] Add retry logic with exponential backoff for transient failures
- [ ] Ensure thread-safe token refresh (prevent race conditions)

### Phase 5: Error Handling
- [ ] Handle refresh token expiration scenarios
- [ ] Provide clear error messages when re-authentication is required
- [ ] Implement graceful degradation with user notifications
- [ ] Add logging for debugging token refresh issues

### Phase 6: Testing
- [ ] Write unit tests for token state manager
- [ ] Write unit tests for refresh token flow
- [ ] Write integration tests for API middleware
- [ ] Test token expiration edge cases
- [ ] Test concurrent request scenarios
- [ ] Verify no regression in existing auth flow

### Phase 7: Documentation & Cleanup
- [ ] Document token refresh behavior in project docs
- [ ] Update configuration documentation
- [ ] Add inline code comments for complex logic
- [ ] Remove debug code and temporary files
- [ ] Final code review preparation

---

## Technical Notes

### OAuth2 Flow
- Standard refresh token grant: `POST /oauth/token` with `grant_type=refresh_token`
- JIRA Cloud typically uses 1-hour access token TTL
- Refresh tokens may have longer TTL or be one-time use

### Security Considerations
- Store refresh tokens securely (not in plain text)
- Consider using system keychain or encrypted storage
- Never log tokens in debug output

### Implementation Patterns
- Consider singleton pattern for token state manager
- Use async/await for refresh operations
- Implement mutex/lock for thread-safe refresh

## Dependencies
- Existing JIRA OAuth2 implementation
- HTTP client library used for API calls
- Secure storage mechanism (TBD)

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| Refresh token not provided by JIRA | Research first; may need different grant type |
| Race conditions during refresh | Implement locking mechanism |
| Secure storage complexity | Start with file-based encrypted storage |
| Breaking existing auth flow | Comprehensive regression testing |

## Success Metrics
- Zero user-reported token expiration issues
- Automatic refresh success rate > 99%
- No increase in authentication-related errors
- Seamless user experience during long sessions
