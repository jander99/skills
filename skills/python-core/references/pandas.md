# Pandas DataFrame Reference

Essential pandas operations for data manipulation.

## DataFrame Creation

**From Dictionary**:
```python
import pandas as pd

data = {
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35],
    'city': ['NYC', 'LA', 'Chicago']
}
df = pd.DataFrame(data)
```

**From List of Dicts**:
```python
data = [
    {'name': 'Alice', 'age': 25},
    {'name': 'Bob', 'age': 30}
]
df = pd.DataFrame(data)
```

**From CSV**:
```python
df = pd.read_csv('data.csv')
df = pd.read_csv('data.csv', index_col=0)  # Use first column as index
```

**From Lists**:
```python
df = pd.DataFrame({
    'A': [1, 2, 3],
    'B': [4, 5, 6]
}, index=['row1', 'row2', 'row3'])
```

## Selection and Indexing

**Column Selection**:
```python
# Single column (returns Series)
ages = df['age']

# Multiple columns (returns DataFrame)
subset = df[['name', 'age']]
```

**Row Selection with loc (label-based)**:
```python
# Single row
row = df.loc[0]

# Multiple rows
rows = df.loc[0:2]

# Rows and columns
subset = df.loc[0:2, ['name', 'age']]

# Boolean indexing
adults = df.loc[df['age'] >= 18]
```

**Row Selection with iloc (position-based)**:
```python
# First row
first = df.iloc[0]

# First 3 rows
first_three = df.iloc[0:3]

# Specific rows and columns by position
subset = df.iloc[0:2, 0:2]
```

**Boolean Indexing**:
```python
# Single condition
young = df[df['age'] < 30]

# Multiple conditions
filtered = df[(df['age'] > 25) & (df['city'] == 'NYC')]

# Using isin()
cities = df[df['city'].isin(['NYC', 'LA'])]
```

## GroupBy Operations

**Basic GroupBy**:
```python
# Group by single column
grouped = df.groupby('city')

# Get group statistics
grouped.mean()
grouped.sum()
grouped.count()
```

**Aggregate Multiple Functions**:
```python
df.groupby('city').agg({
    'age': ['mean', 'min', 'max'],
    'salary': 'sum'
})
```

**Custom Aggregation**:
```python
df.groupby('city')['age'].agg(
    mean_age='mean',
    max_age='max',
    count='count'
)
```

**Iterate Over Groups**:
```python
for name, group in df.groupby('city'):
    print(f"City: {name}")
    print(group)
```

## Merge and Join

**Merge (SQL-style joins)**:
```python
df1 = pd.DataFrame({'key': ['A', 'B', 'C'], 'value1': [1, 2, 3]})
df2 = pd.DataFrame({'key': ['A', 'B', 'D'], 'value2': [4, 5, 6]})

# Inner join (default)
merged = pd.merge(df1, df2, on='key')

# Left join
left_merged = pd.merge(df1, df2, on='key', how='left')

# Outer join
outer_merged = pd.merge(df1, df2, on='key', how='outer')
```

**Join on Index**:
```python
df1.set_index('key').join(df2.set_index('key'))
```

**Concat**:
```python
# Vertical concat (stack rows)
combined = pd.concat([df1, df2], axis=0)

# Horizontal concat (add columns)
combined = pd.concat([df1, df2], axis=1)
```

## Data Manipulation

**Add/Modify Columns**:
```python
df['new_col'] = df['age'] * 2
df['category'] = df['age'].apply(lambda x: 'adult' if x >= 18 else 'minor')
```

**Drop Columns/Rows**:
```python
df.drop('column_name', axis=1)  # Drop column
df.drop([0, 1], axis=0)  # Drop rows by index
```

**Sort**:
```python
df.sort_values('age')  # Ascending
df.sort_values('age', ascending=False)  # Descending
df.sort_values(['city', 'age'])  # Multiple columns
```

**Handle Missing Data**:
```python
df.dropna()  # Drop rows with any NaN
df.fillna(0)  # Fill NaN with 0
df['age'].fillna(df['age'].mean())  # Fill with mean
```

## Performance Tips

**Use Vectorized Operations**:
```python
# Good (vectorized)
df['result'] = df['col1'] + df['col2']

# Bad (slow loop)
for i in range(len(df)):
    df.loc[i, 'result'] = df.loc[i, 'col1'] + df.loc[i, 'col2']
```

**Use Categories for Repeated Strings**:
```python
df['city'] = df['city'].astype('category')  # Saves memory
```

**Read CSV in Chunks**:
```python
for chunk in pd.read_csv('large.csv', chunksize=10000):
    process(chunk)
```

**Use query() for Complex Filters**:
```python
# Faster than boolean indexing for complex queries
df.query('age > 25 and city == "NYC"')
```

## Common Operations

**Value Counts**:
```python
df['city'].value_counts()
```

**Unique Values**:
```python
df['city'].unique()
df['city'].nunique()  # Count of unique values
```

**Apply Functions**:
```python
df['age'].apply(lambda x: x * 2)
df.apply(lambda row: row['age'] + row['salary'], axis=1)
```

**String Operations**:
```python
df['name'].str.upper()
df['name'].str.contains('Alice')
df['name'].str.split(' ')
```

**Export**:
```python
df.to_csv('output.csv', index=False)
df.to_json('output.json')
df.to_excel('output.xlsx')
```
