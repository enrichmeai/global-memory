package com.example.app.items;

import com.example.app.api.ErrorAdvice;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ItemController.class)
@Import({ItemService.class, InMemoryItemStore.class, ErrorAdvice.class})
class ItemControllerTest {

    @Autowired
    MockMvc mvc;

    @Test
    void createReturns201WithLocationThenGetFindsIt() throws Exception {
        MvcResult created = mvc.perform(post("/api/items").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"first\",\"description\":\"one\"}"))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", containsString("/api/items/")))
                .andExpect(jsonPath("$.name").value("first"))
                .andReturn();
        String location = created.getResponse().getHeader("Location");
        mvc.perform(get(location)).andExpect(status().isOk()).andExpect(jsonPath("$.description").value("one"));
    }

    @Test
    void invalidInputIsA400ProblemNamingTheField() throws Exception {
        mvc.perform(post("/api/items").contentType(MediaType.APPLICATION_JSON).content("{\"name\":\" \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.type").value("urn:problem:validation"))
                .andExpect(jsonPath("$.fields.name").exists());
    }

    @Test
    void aMissingItemIsA404ProblemThatDoesNotEchoTheId() throws Exception {
        mvc.perform(get("/api/items/nope-<script>"))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.type").value("urn:problem:not-found"))
                // The message is fixed; only "instance", the request path RFC 9457 defines, carries it, URL-encoded.
                .andExpect(jsonPath("$.detail").value("No item with that id."));
        mvc.perform(delete("/api/items/nope")).andExpect(status().isNotFound());
    }

    @Test
    void malformedJsonIsA400Problem() throws Exception {
        mvc.perform(post("/api/items").contentType(MediaType.APPLICATION_JSON).content("{not json"))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void theWrongMethodIsA405Problem() throws Exception {
        mvc.perform(put("/api/items"))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }
}
