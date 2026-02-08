package com.stocat.gateway.infrastructure.consul;

import com.ecwid.consul.v1.ConsulClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

@Configuration
public class ConsulClientConfig {

    @Bean
    @Primary
    public ConsulClient consulClient(
            @Value("${spring.cloud.consul.host:localhost}") String host,
            @Value("${spring.cloud.consul.port:8500}") int port
    ) {
        return new ConsulClient(host, port);
    }
}
