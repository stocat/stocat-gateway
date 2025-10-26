package com.stocat.gateway.security;

import com.ecwid.consul.v1.ConsulClient;
import com.ecwid.consul.v1.Response;
import com.ecwid.consul.v1.kv.model.GetValue;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class ConsulJwtSecretProvider implements JwtSecretProvider {

    private final ConsulClient consulClient;
    private final String keyPath;

    public ConsulJwtSecretProvider(
            ConsulClient consulClient,
            @Value("${jwt.secret.key:config/common/secrets/jwt-secret}") String keyPath
    ) {
        this.consulClient = consulClient;
        this.keyPath = keyPath;
    }

    @Override
    public String loadSecret() {
        Response<GetValue> resp = consulClient.getKVValue(keyPath);
        GetValue value = resp.getValue();
        if (value == null) return null;
        String decoded = value.getDecodedValue();
        return decoded != null ? decoded.trim() : null;
    }
}
