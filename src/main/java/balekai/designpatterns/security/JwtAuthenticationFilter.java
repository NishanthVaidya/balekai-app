package balekai.designpatterns.security;

import balekai.designpatterns.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
@Slf4j
@Profile("!test")
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String requestPath = request.getRequestURI();
        // Permissive CORS headers (temporary until CloudFront origins stabilized)
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,PATCH,OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Authorization,Content-Type,Accept,Origin,X-Requested-With");
        response.setHeader("Access-Control-Expose-Headers", "Authorization,Content-Type");
        response.setHeader("Vary", "Origin, Access-Control-Request-Method, Access-Control-Request-Headers");

        // Allow preflight requests to pass through immediately
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);
            return;
        }
        
        // Skip JWT validation for public endpoints
        if (isPublicEndpoint(requestPath)) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            log.warn("JWT Authentication failed: No valid Authorization header for path: {}", requestPath);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Unauthorized: No valid token provided\"}");
            return;
        }

        try {
            String token = authHeader.substring(7);
            String email = jwtService.extractUsername(token);
            
            if (email != null && !email.isEmpty()) {
                // Store the authenticated user email in request attributes for controllers to use
                request.setAttribute("authenticatedUserEmail", email);
                log.debug("JWT Authentication successful for user: {} on path: {}", email, requestPath);
                filterChain.doFilter(request, response);
            } else {
                log.warn("JWT Authentication failed: Invalid token for path: {}", requestPath);
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write("{\"error\":\"Unauthorized: Invalid token\"}");
            }
        } catch (Exception e) {
            log.error("JWT Authentication error for path {}: {}", requestPath, e.getMessage());
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Unauthorized: Token validation failed\"}");
        }
    }

    private boolean isPublicEndpoint(String path) {
        return path.startsWith("/auth/") || 
               path.equals("/") || 
               path.equals("/health") ||
               path.startsWith("/h2-console/");
    }
}
