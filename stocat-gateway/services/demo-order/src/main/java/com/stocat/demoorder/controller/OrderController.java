package com.stocat.demoorder.controller;

import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class OrderController {

    @GetMapping("/orders")
    Map<String, Object> list(@RequestHeader HttpHeaders headers) {
        return Map.of(
                "ok", true,
                "svc", "orders",
                "headers", headers.toSingleValueMap()
        );
    }
}
