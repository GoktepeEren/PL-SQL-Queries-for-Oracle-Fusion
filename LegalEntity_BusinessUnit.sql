select hou.name BU_NAME, hou.SHORT_CODE , le.NAME Legal_ENtity, led.NAME Ledger_Name
from hr_operating_units hou,
xla_gl_ledgers led,
Xle_entity_profiles le
where hou.default_legal_context_id = le.legal_entity_id
and led.ledger_id = hou.set_of_books_id