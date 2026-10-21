package com.example.app.items;

import java.util.List;
import java.util.Optional;

/** Where items live. Swap the implementation (a database) without touching the controller. */
public interface ItemStore {
    List<Item> all();
    Optional<Item> find(String id);
    Item save(Item item);
    boolean delete(String id);
}
