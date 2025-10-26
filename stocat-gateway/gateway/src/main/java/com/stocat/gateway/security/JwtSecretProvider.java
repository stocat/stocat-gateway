package com.stocat.gateway.security;

public interface JwtSecretProvider {
    String loadSecret();
}
