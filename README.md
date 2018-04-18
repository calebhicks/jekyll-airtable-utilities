# Jekyll Airtable Utilities

A handful of Jekyll plugins for integrating data stored in Airtable. 

To install, place the included files in the `_plugins` directory in your Jekyll project.

## Airtable Fetch

Airtable Fetch pulls a list of tables from a given base, combines all of the records into a flat JSON file with some small transformations, and saves the file in the `_data` directory to make the data available to your Jekyll site.

To configure, add an `airtable` key to your `_config.yml` file, provide your API key, a list of tables and sheets you'd like to pull. 

```
airtable:
  api_key: # Airtable API key available in the API documentation for your base
  tables:
    - name: Student Master Tracker
      app_id: appXXX # Airtable app ID found in the API documentation for your base
      sheets: 
        - name: students
          view: grid view
        - name: daily standup
          view: grid view
        - name: weekly retrospective
          view: grid view
```

## Airtable Page Generator

I'm very sorry for not knowing this, but I'm pretty sure this is based off of the [Jekyll-Datapage_gen](https://github.com/avillafiorita/jekyll-datapage_gen) project. But it's built specifically for integrating with data pulled using Airtable Fetch.

To configure, add an `airtable_pages` key to your `_config.yml` file, and configuration options for the table name, the type (a trimmed version of the sheet name in Airtable), the desired output subdirectory, and the name of the template you'd like the site to use.

The data will be provided as the `page.context` on each page. Unescaped record fields can be used using bracket syntax. For example, if you assigned the `page.context` to a `student` variable, you could use the "Project Manager" record field by using `student["Project Manager"]`.

```
airtable_pages:
  - table: Student Master Tracker
    type: student
    name: Name
    subdirectory: students
    template: student
  - table: Student Master Tracker
    type: instructor
    name: Name
    subdirectory: instructors
    template: instructor
  - table: Student Master Tracker
    type: project manager
    name: Name
    subdirectory: pms
    template: pm
```

## Airtable Filters

These filters facilitate handling related records from Airtable. When you pull data from the Airtable API, a linked record is referenced only by its record identifier. 

If you were trying to get access to a `student["Project Manager"]` value that is linked to a record in the "Project Managers" table, `{{ student["Project Manager"] }} will only return the record ID, not the record itself.

So the Airtable Filters plugin defines a `record(id, base)` filter, which can be used on the identifier to fetch the record itself. The following snippet would output the full `pm` record.

```
{% assign pm = student["Project Manager"] | record: student.base %}
{{ pm }}
```

The `student.base` value is included as part of the transformation that occurs when using "Airtable Fetch", and is required here to allow the filter to fetch from the correct data file without recursively searching all of your data. It's not ideal, but it works, and keeps lookups speedy even with large datasets.

Because Airtable allows you to link multiple records in a single field, oftentimes you'll be working with an array of record identifiers. If, for example, I could link multiple "Project Managers" to a given student, I may need to either use the `first` filter, or, if I want all of the records, use the included `map_ids` filter.

```
{% assign this_week_retros = instructor["All Weekly Retrospectives"] | map_ids: instructor.base %}
```

## Contributions

Want to contribute? Add an issue or submit a pull request. I can't promise to update or provide long-term support on these, but I use them in production almost every day.
