--To disable this model, set the using_credit_memo variable within your dbt_project.yml file to False.
{{ config(enabled=var('using_credit_memo', True)) }}

with credit_memos as (
    select *
    from {{ref('stg_quickbooks__credit_memo')}}
),

credit_memo_lines as (
    select *
    from {{ref('stg_quickbooks__credit_memo_line')}}
),

items as (
    select *
    from {{ref('stg_quickbooks__item')}}
),

accounts as (
    select *
    from {{ ref('stg_quickbooks__account') }}
),

df_accounts as (
    select
        max(account_id) as account_id
    from accounts

    where account_sub_type = 'DiscountsRefundsGiven'
),

credit_memo_join as (
    select
        credit_memos.credit_memo_id as transaction_id,
        credit_memos.transaction_date,
        credit_memo_lines.amount,
        -- case when credit_memo_lines.sales_item_account_id is null and  credit_memo_lines.sales_item_item_id is null
        --     then credit_memo_lines.discount_account_id
        -- when credit_memo_lines.discount_account_id is null and credit_memo_lines.sales_item_account_id is null
        --     then coalesce(items.income_account_id, items.expense_account_id, items.asset_account_id) --tried asset
        --     else credit_memo_lines.sales_item_account_id
                -- end as account_id
        coalesce(credit_memo_lines.sales_item_account_id, items.income_account_id) as account_id
                
    from credit_memos

    inner join credit_memo_lines
        on credit_memos.credit_memo_id = credit_memo_lines.credit_memo_id

    left join items
        on credit_memo_lines.sales_item_item_id = items.item_id

    where coalesce(credit_memo_lines.discount_account_id, credit_memo_lines.sales_item_account_id, credit_memo_lines.sales_item_item_id) is not null
),

final as (
    select
        transaction_id,
        transaction_date,
        amount * -1 as amount,
        --amount as amount,
        account_id,
        'credit' as transaction_type,
        'credit_memo' as transaction_source
    from credit_memo_join

    union all

    select 
        transaction_id,
        transaction_date,
        amount * -1 as amount,
        --amount as amount,
        df_accounts.account_id,
        'debit' as transaction_type,
        'credit_memo' as transaction_source
    from credit_memo_join

    cross join df_accounts
)

select *
from final