package com.example.app.items;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/** The rules for items. HTTP-free, so it can be tested and reused on its own. */
@Service
public class ItemService {

    private final ItemStore store;

    public ItemService(ItemStore store) {
        this.store = store;
    }

    public List<Item> list() {
        return store.all();
    }

    public Item get(String id) {
        return store.find(id).orElseThrow(() -> new ItemNotFoundException(id));
    }

    public Item create(NewItem request) {
        Item item = new Item(UUID.randomUUID().toString(), request.name().strip(),
                request.description() == null ? "" : request.description().strip());
        return store.save(item);
    }

    public void delete(String id) {
        if (!store.delete(id)) {
            throw new ItemNotFoundException(id);
        }
    }
}
