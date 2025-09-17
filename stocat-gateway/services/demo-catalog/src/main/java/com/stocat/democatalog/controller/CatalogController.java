package com.stocat.democatalog.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class CatalogController {

    @GetMapping("/products")
    Map<String, Object> list() {
        return Map.of("ok", true, "svc", "catalog");
    }
}
