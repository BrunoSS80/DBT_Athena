{% macro athena__create_table_as(relation, sql) %}
    create table {{relation}} as {{sql}}
{% endmacro %}