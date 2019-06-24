## Wildcard bracket notation on array

### Setup
Selector: `$[*]`

    [
        "string",
        42,
        {
            "key": "value"
        },
        [0, 1]
    ]

### Results
####  Gold Standard (consensus)

    [
      "string", 
      42, 
      {
        "key": "value"
      }, 
      [
        0, 
        1
      ]
    ]

#### Clojure (json-path)

    [
      "string", 
      42, 
      {
        "key": "value"
      }, 
      0, 
      1
    ]

#### Rust (jsonpath_lib)

    [
      [
        "string", 
        42, 
        {
          "key": "value"
        }, 
        [
          0, 
          1
        ]
      ]
    ]
