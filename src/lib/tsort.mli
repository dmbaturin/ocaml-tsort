type 'a sort_result = Sorted of 'a list | ErrorNonexistent of 'a list | ErrorCycle of 'a list

val sort : ('a * 'a list) list -> 'a sort_result
