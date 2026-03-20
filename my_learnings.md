# Pandas `melt()` Notes

## Definition

`melt()` is a pandas function used to reshape data from **wide format** to **long format** by turning multiple columns into rows.

Documentation:

- `pandas.DataFrame.melt`: https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.melt.html
- `pandas.melt`: https://pandas.pydata.org/docs/dev/reference/api/pandas.melt.html

## What `melt()` does

`melt()` converts a DataFrame from **wide format** to **long format**.

- Wide format: same kind of data spread across many columns
- Long format: that data stacked into rows

It is useful when multiple columns actually represent one variable, and those column names should become values in a new column.

## GDP example

Before:

| Country Name | Country Code | 2020 | 2021 | 2022 |
|---|---|---:|---:|---:|
| India | IND | 1900 | 2100 | 2300 |

After `melt()`:

| Country Name | Country Code | year | value |
|---|---|---|---:|
| India | IND | 2020 | 1900 |
| India | IND | 2021 | 2100 |
| India | IND | 2022 | 2300 |

So `melt()` takes year columns like `2020`, `2021`, `2022` and turns:

- the column names into one column: `year`
- the values inside those columns into one column: `value`

## Syntax used

```python
gdp_long = gdp.melt(
    id_vars=['Country Name', 'Country Code'],
    value_vars=year_columns,
    var_name='year',
    value_name='value'
)
```

## Meaning of the parameters

### `id_vars`

Columns to keep fixed.

In this case:

```python
id_vars=['Country Name', 'Country Code']
```

These stay repeated on each row after melting.

### `value_vars`

Columns to unpivot / stack into rows.

In this case:

```python
value_vars=year_columns
```

This means all the year columns will be converted from separate columns into rows.

### `var_name`

Name of the new column that stores the **old column names**.

In this case:

```python
var_name='year'
```

Because the old column names are years like `2020`, `2021`, `2022`.

### `value_name`

Name of the new column that stores the **actual values** from those old columns.

In this case:

```python
value_name='value'
```

This means the GDP numbers go into a column called `value`.

`value` is just a placeholder name. It could also be:

- `gdp_per_capita`
- `gdp_value`
- `amount`
- `metric_value`

Example:

```python
gdp_long = gdp.melt(
    id_vars=['Country Name', 'Country Code'],
    value_vars=year_columns,
    var_name='year',
    value_name='gdp_per_capita'
)
```

This is often clearer than using just `value`.

## Why `var_name` and `value_name` are different

They store two different things:

- `var_name` stores the old column labels
- `value_name` stores the cell values inside those columns

Example:

- old column label: `2021`
- old cell value: `2100`

After melting:

- `year = 2021`
- `value = 2100`

So both names are needed because one column is for the **category/label**, and one is for the **actual measurement**.

## Other use cases for `melt()`

### Monthly sales

Before:

| Product | Jan | Feb | Mar |
|---|---:|---:|---:|
| A | 10 | 20 | 15 |

After:

| Product | month | sales |
|---|---|---:|
| A | Jan | 10 |
| A | Feb | 20 |
| A | Mar | 15 |


## Why use `str(col).strip().isdigit()` instead of `col.isdigit()`

Code:

```python
year_columns = [col for col in gdp.columns if str(col).strip().isdigit()]
```

This is safer than:

```python
[col for col in gdp.columns if col.isdigit()]
```

### Why `str()`

`isdigit()` is a string method. If a column name is not a string, `col.isdigit()` can fail.

Example:

```python
df.columns = ['Country Name', '1960', 1961]
```

- `'1960'.isdigit()` works
- `1961.isdigit()` fails because `1961` is an integer

Using `str(col)` converts the column name to text first.

### Why `strip()`

`strip()` removes spaces before and after the text.

Example:

```python
' 1960 '.isdigit()           # False
' 1960 '.strip().isdigit()   # True
```

So:

```python
str(col).strip().isdigit()
```

means:

- convert column name to string
- remove extra spaces
- check if the result contains only digits

This makes the year-column check more robust.

## Why not check dtype instead

This:

```python
year_columns = [col for col in gdp.columns if str(col).strip().isdigit()]
```

checks the **column name**.

That is correct because we want to identify columns named like years.

Checking dtype would answer a different question: what data type is inside the column?

But a numeric column is not necessarily a year column, so dtype is not a reliable way to identify year headers.

## Pandas docs

Official documentation:

- `pandas.DataFrame.melt`: https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.melt.html
- `pandas.melt`: https://pandas.pydata.org/docs/dev/reference/api/pandas.melt.html
