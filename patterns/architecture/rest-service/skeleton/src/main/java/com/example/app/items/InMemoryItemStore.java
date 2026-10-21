package com.example.app.items;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Component
class InMemoryItemStore implements ItemStore {

    private final Map<String, Item> items = new ConcurrentHashMap<>();

    @Override public List<Item> all() { return new ArrayList<>(items.values()); }
    @Override public Optional<Item> find(String id) { return Optional.ofNullable(items.get(id)); }
    @Override public Item save(Item item) { items.put(item.id(), item); return item; }
    @Override public boolean delete(String id) { return items.remove(id) != null; }
}
