package dae.pc.voters.service;

import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Path;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * Builds a Specification from a list request's query parameters. Parameters that are absent or blank are ignored,
 * each filter that is present is ANDed with the others.
 */
public class Filters<E> {

    private final Map<String, String> params;
    private final List<Specification<E>> specs = new ArrayList<>();

    public Filters(Map<String, String> params) {
        this.params = params;
    }

    public String get(String name) {
        String value = params.get(name);
        return value == null || value.isBlank() ? null : value.trim();
    }

    public Integer getInt(String name) {
        String value = get(name);
        if (value == null) {
            return null;
        }
        try {
            return Integer.valueOf(value);
        } catch (NumberFormatException e) {
            throw new BadRequestException(name + " must be a number, not '" + value + "'");
        }
    }

    public Boolean getBoolean(String name) {
        String value = get(name);
        return value == null ? null : Boolean.valueOf(value);
    }

    public LocalDate getDate(String name) {
        String value = get(name);
        if (value == null) {
            return null;
        }
        try {
            return LocalDate.parse(value);
        } catch (DateTimeParseException e) {
            throw new BadRequestException(name + " must be a date, yyyy-mm-dd, not '" + value + "'");
        }
    }

    /**
     * Adds a filter if the parameter is present, built from its value.
     */
    public <V> Filters<E> add(V value, Function<V, Specification<E>> spec) {
        if (value != null) {
            specs.add(spec.apply(value));
        }
        return this;
    }

    /**
     * Adds a filter if the parameter is present, matching the attribute exactly.
     */
    public Filters<E> equal(Object value, Function<Root<E>, Path<?>> attribute) {
        return add(value, v -> (root, query, cb) -> cb.equal(attribute.apply(root), v));
    }

    public Specification<E> build() {
        return Specification.allOf(specs);
    }

    /**
     * Case-insensitive match of the value anywhere in the expression.
     */
    public static Predicate contains(CriteriaBuilder cb, Expression<String> expression, String value) {
        return cb.like(cb.lower(expression), "%" + escape(value.toLowerCase()) + "%", '\\');
    }

    /**
     * Case-insensitive match of the expression's start.
     */
    public static Predicate startsWith(CriteriaBuilder cb, Expression<String> expression, String value) {
        return cb.like(cb.lower(expression), escape(value.toLowerCase()) + "%", '\\');
    }

    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }

    /**
     * Postcodes are stored in upper case without spaces, see load-addresses.py.
     */
    public static String normalisePostcode(String postcode) {
        return postcode == null ? null : postcode.toUpperCase().replace(" ", "");
    }
}
