### Master pipeline p0
```
p0:  Execute p1 ─► Execute p2 ─► Execute p3 ─► Execute p4      (On success)
```
- Each Execute Pipeline activity has **Wait on completion** ticked; otherwise p0 only *starts* a child and moves on, so p2 would read data p1 hasn't copied yet.
- `@pipeline().Pipeline` inside p4 returns **`pl4_gold_sql_database`** (p4, the pipeline running the data flow), not p0.

---

