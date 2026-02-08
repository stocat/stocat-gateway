package com.stocat.gateway.security;

import com.stocat.gateway.security.jwt.JwtSecretProvider;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.oauth2.jwt.NimbusReactiveJwtDecoder;
import org.springframework.security.oauth2.jwt.ReactiveJwtDecoder;
import org.springframework.security.web.server.SecurityWebFilterChain;

import javax.crypto.SecretKey;

@Configuration
public class SecurityConfig {
    private final JwtSecretProvider jwtSecretProvider;

    public SecurityConfig(JwtSecretProvider jwtSecretProvider) {
        this.jwtSecretProvider = jwtSecretProvider;
    }

    @Bean
    SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
                .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
                .authorizeExchange(ex -> ex
                        .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .pathMatchers(
                                "/actuator/**",
                                "/auth/login",
                                "/auth/signup",
                                "/auth/find-id",
                                "/auth/find-password",
                                "/auth/summary"
                        ).permitAll()
                        .anyExchange().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> { }));
        return http.build();
    }

    @Bean
    @RefreshScope
    ReactiveJwtDecoder jwtDecoder() {
        SecretKey signingKey = jwtSecretProvider.getSigningKey();
        return NimbusReactiveJwtDecoder.withSecretKey(signingKey).build();
    }
}
