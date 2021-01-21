--To disable this model, set the using_journal_entry variable within your dbt_project.yml file to False.
{{ config(enabled=var('using_journal_entry', True)) }}

with journal_entries as (
    select *
    from {{ref('stg_quickbooks__journal_entry')}}
),

journal_entry_lines as (
    select *
    from {{ref('stg_quickbooks__journal_entry_line')}}
),

final as (
    select
        journal_entries.journal_entry_id as transaction_id,
        journal_entries.transaction_date,
        journal_entry_lines.amount,
        journal_entry_lines.account_id,
        lower(journal_entry_lines.posting_type) as transaction_type,
        'journal_entry' as transaction_source
    from journal_entries

    inner join journal_entry_lines
        on journal_entries.journal_entry_id = journal_entry_lines.journal_entry_id
)

select *
from final