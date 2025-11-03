package com.stocat.gateway.infrastructure.consul;

import com.ecwid.consul.v1.ConsulClient;
import com.ecwid.consul.v1.Response;
import com.ecwid.consul.v1.kv.model.GetValue;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.refresh.ContextRefresher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Objects;

@Slf4j
@Component
public class ConsulJwtSecretWatcher {

    private final ConsulClient consulClient;
    private final ContextRefresher contextRefresher;
    private final String keyPath;
    private volatile Long lastModifyIndex;

    public ConsulJwtSecretWatcher(ConsulClient consulClient,
                                  ContextRefresher contextRefresher,
                                  @Value("${jwt.secret.key:config/common/secrets/jwt-secret}") String keyPath) {
        this.consulClient = consulClient;
        this.contextRefresher = contextRefresher;
        this.keyPath = keyPath;
    }

    @Scheduled(fixedDelayString = "${jwt.secret.watch-interval:5000}")
    public void pollForChanges() {
        try {
            Response<GetValue> resp = consulClient.getKVValue(keyPath);
            GetValue value = resp.getValue();
            Long modifyIndex = value != null ? value.getModifyIndex() : null;

            if (modifyIndex == null) {
                return;
            }

            Long prev = lastModifyIndex;
            if (!Objects.equals(prev, modifyIndex)) {
                lastModifyIndex = modifyIndex;
                log.info("JWT secret KV changed ({} -> {}), refreshing context", prev, modifyIndex);
                contextRefresher.refresh();
            }
        } catch (Exception e) {
            log.warn("Failed to poll JWT secret from Consul at '{}': {}", keyPath, e.toString());
        }
    }
}

