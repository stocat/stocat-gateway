package com.stocat.gateway.security.filter;

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
public class MemberIdHeaderFilter implements GlobalFilter, Ordered {

    private static final String MEMBER_ID_HEADER = "X-MEMBER-ID";
    private static final String AUTHORIZATION_HEADER = "Authorization";

    private ServerHttpRequest withMemberId(ServerHttpRequest request, String memberId) {
        return request.mutate()
                .headers(headers -> {
                    headers.remove(AUTHORIZATION_HEADER);
                    headers.set(MEMBER_ID_HEADER, memberId);
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
                    String memberId = Objects.toString(jwt.getClaims().getOrDefault("memberId", jwt.getSubject()), "");
                    return withMemberId(exchange.getRequest(), memberId);
                })
                .defaultIfEmpty(withMemberId(exchange.getRequest(), ""))
                .flatMap(req -> chain.filter(exchange.mutate().request(req).build()));
    }

    @Override
    public int getOrder() {
        // Run early in the Gateway filter chain, after security has populated the principal
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }
}
