package com.example.app.items;

import com.example.app.api.ErrorAdvice;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** A failure nobody planned for is a generic 500 problem; its message stays in the server log. */
@WebMvcTest(ItemController.class)
@Import({ItemService.class, ErrorAdvice.class})
class UnexpectedErrorTest {

    @Autowired
    MockMvc mvc;

    @MockitoBean
    ItemStore store;

    @Test
    void anUnexpectedFailureIsA500ProblemWithoutItsMessage() throws Exception {
        when(store.all()).thenThrow(new IllegalStateException("connection to db-internal-7 refused"));
        mvc.perform(get("/api/items"))
                .andExpect(status().isInternalServerError())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.detail").value("Something went wrong."))
                .andExpect(content().string(not(containsString("db-internal-7"))));
    }
}
