module ListTyped exposing
    ( ListTyped, MaybeEmpty, NotEmpty
    , empty, only, fromCons, fromTuple, fromList
    , cons, append, appendNonEmpty
    , map, toList, toTuple
    )

{-|


## types

@docs ListTyped, MaybeEmpty, NotEmpty


## create

@docs empty, only, fromCons, fromTuple, fromList


## modify

@docs cons, append, appendNonEmpty


## transform

@docs map, toList, toTuple

-}

import MaybeTyped exposing (MaybeTyped(..), just, nothing)


type alias ListTyped emptyOrNot_ a =
    MaybeTyped emptyOrNot_ ( a, List a )


type alias NotEmpty =
    MaybeTyped.Just { notEmpty : () }


type alias MaybeEmpty =
    MaybeTyped.MaybeNothing { maybeEmpty : () }


{-| A `ListTyped` without elements.
Equivalent to `MaybeTyped.nothing`.
-}
empty : ListTyped MaybeEmpty a
empty =
    nothing


{-| A `ListTyped` with just 1 element.

    ListTyped.only ":)"
    --> ListTyped.empty |> ListTyped.cons ":)"

-}
only : a -> ListTyped notEmpty_ a
only onlyElement =
    fromCons onlyElement []


{-| Convert a non-empty list tuple `( a, List a )` to a `ListTyped notEmpty_ a`.

Equivalent to `MaybeTyped.just`.

-}
fromTuple : ( a, List a ) -> ListTyped notEmpty_ a
fromTuple nonEmptyList =
    just nonEmptyList


{-| Build a `ListTyped notEmpty_ a` from its head and tail.
-}
fromCons : a -> List a -> ListTyped notEmpty_ a
fromCons head tail =
    fromTuple ( head, tail )


{-| Convert a `List a` to a `ListTyped MaybeEmpty a`.

    [] |> ListTyped.fromList
    --> ListTyped.empty

    [ "hello", "emptiness" ] |> ListTyped.fromList
    --> ListTyped.fromCons "hello" [ "emptiness" ]
    --: ListTyped MaybeEmpty String

When constructing from known elements, always prefer

    ListTyped.fromCons "hello" [ "emptiness" ]

-}
fromList : List a -> ListTyped MaybeEmpty a
fromList list_ =
    case list_ of
        [] ->
            empty

        head :: tail ->
            fromTuple ( head, tail )



--


{-| Add an element to the front of a list.

    ListTyped.fromCons 2 [ 3 ] |> ListTyped.cons 1
    --> ListTyped.fromCons 1 [ 2, 3 ]

    ListTyped.empty |>  ListTyped.cons 1
    --> ListTyped.only 1

-}
cons : a -> ListTyped emptyOrNot_ a -> ListTyped NotEmpty a
cons toPutBeforeAllOtherElements =
    \list ->
        case list of
            NothingTyped _ ->
                only toPutBeforeAllOtherElements

            JustTyped ( head, tail ) ->
                fromCons toPutBeforeAllOtherElements (head :: tail)


{-| Glue the elements of a `ListTyped NotEmpty ...` to the end of a `ListTyped`.

    ListTyped.empty
        |> ListTyped.appendNonEmpty
            (ListTyped.fromCons 1 [ 2 ])
        |> ListTyped.appendNonEmpty
            (ListTyped.fromCons 3 [ 4, 5 ])
    --> ListTyped.fromCons 1 [ 2, 3, 4, 5 ]

Prefer [`append`](#append) if the piped `ListTyped` is already known as `NotEmpty`
or if both are `MaybeEmpty`.

-}
appendNonEmpty :
    ListTyped NotEmpty a
    -> ListTyped emptyOrNot_ a
    -> ListTyped NotEmpty a
appendNonEmpty nonEmptyToAppend =
    \list ->
        case list of
            NothingTyped _ ->
                nonEmptyToAppend

            JustTyped ( head, tail ) ->
                fromCons head (tail ++ toList nonEmptyToAppend)


{-| Glue the elements of a `ListTyped` to the end of a `ListTyped`.

    ListTyped.fromCons 1 [ 2 ]
        |> ListTyped.append
            (ListTyped.fromCons [ 3, 4, 5 ])
    --> ListTyped.fromCons 1 [ 2, 3, 4, 5 ]

Prefer this over [`appendNonEmpty`](#appendNonEmpty) if the piped `ListTyped` is already known as `NotEmpty`
or if both are `MaybeEmpty`.

-}
append :
    ListTyped MaybeEmpty a
    -> ListTyped isEmpty a
    -> ListTyped isEmpty a
append toAppend =
    \list ->
        case ( list, toAppend ) of
            ( NothingTyped is, NothingTyped _ ) ->
                NothingTyped is

            ( NothingTyped _, JustTyped nonEmptyToAppend ) ->
                fromTuple nonEmptyToAppend

            ( JustTyped ( head, tail ), _ ) ->
                fromCons head (tail ++ toList toAppend)



--


{-| Apply a function to every element.

    ListTyped.fromCons 1 [ 4, 9 ]
        |> ListTyped.map negate
    --> ListTyped.fromCons -1 [ -4, -9 ]

-}
map : (a -> b) -> ListTyped isEmpty a -> ListTyped isEmpty b
map change =
    MaybeTyped.map (Tuple.mapBoth change (List.map change))


{-| Convert any `ListTyped` to a `List`.

    ListTyped.fromCons 1 [ 7 ]
        |> ListTyped.toList
    --> [ 1, 7 ]

-}
toList : ListTyped emptyOrNot_ a -> List a
toList list =
    case list of
        JustTyped ( head, tail ) ->
            head :: tail

        NothingTyped _ ->
            []


{-| Convert a `ListTyped notEmpty a` to a non-empty list tuple `( a, List a )`.

Equivalent to `MaybeTyped.value`.

-}
toTuple : ListTyped NotEmpty a -> ( a, List a )
toTuple typedList =
    typedList |> MaybeTyped.value