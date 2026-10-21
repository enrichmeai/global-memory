package com.example.app.items;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;

/** HTTP only: status codes, validation and mapping. The rules live in {@link ItemService}. */
@RestController
@RequestMapping("/api/items")
public class ItemController {

    private final ItemService items;

    public ItemController(ItemService items) {
        this.items = items;
    }

    @GetMapping
    public List<Item> list() {
        return items.list();
    }

    @GetMapping("/{id}")
    public Item get(@PathVariable String id) {
        return items.get(id);
    }

    @PostMapping
    public ResponseEntity<Item> create(@Valid @RequestBody NewItem request) {
        Item created = items.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest().path("/{id}")
                .buildAndExpand(created.id()).toUri();
        return ResponseEntity.created(location).body(created);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        items.delete(id);
        return ResponseEntity.noContent().build();
    }
}
