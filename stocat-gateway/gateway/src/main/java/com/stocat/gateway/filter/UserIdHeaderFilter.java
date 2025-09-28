package com.stocat.gateway.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.Objects;

@Slf4j
@Component
public class UserIdHeaderFilter implements GlobalFilter, Ordered {

    private static final String USER_ID_HEADER = "X-USER-ID";
    private static final String AUTHORIZATION_HEADER = "Authorization";

    private ServerHttpRequest withUserId(ServerHttpRequest request, String userId) {
        log.info("withUserId");
        return request.mutate()
                .headers(headers -> {
                    headers.remove(AUTHORIZATION_HEADER);
                    headers.set(USER_ID_HEADER, userId);
                })
                .build();
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return ReactiveSecurityContextHolder.getContext()
                .map(SecurityContext::getAuthentication)
                .ofType(JwtAuthenticationToken.class)
                .map(jwtAuth -> {
                    Jwt jwt = jwtAuth.getToken();
                    String userId = Objects.toString(jwt.getClaims().getOrDefault("userId", jwt.getSubject()), "");
                    return withUserId(exchange.getRequest(), userId);
                })
                .defaultIfEmpty(withUserId(exchange.getRequest(), ""))
                .flatMap(req -> chain.filter(exchange.mutate().request(req).build()));
    }

    @Override
    public int getOrder() {
        // Run early in the Gateway filter chain, after security has populated the principal
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }
}
