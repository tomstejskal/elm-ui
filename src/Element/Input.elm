module Element.Input exposing
    ( button
    , checkbox, defaultCheckbox
    , text, Placeholder, placeholder
    , username, newPassword, currentPassword, email, search, spellChecked
    , multiline
    , slider, Thumb, thumb, defaultThumb
    , radio, radioRow, Option, option, optionWith, OptionState(..)
    , Label, labelAbove, labelBelow, labelLeft, labelRight, labelHidden
    , focusedOnLoad
    )

{-|

@docs button

@docs checkbox, defaultCheckbox


## Text Input

@docs text, Placeholder, placeholder

We can also give a hint about what type of content our text field contains. This will allow things like autofill to work correctly.

@docs username, newPassword, currentPassword, email, search, spellChecked


## Multiline Text

@docs multiline


## Slider

@docs slider, Thumb, thumb, defaultThumb


## Radio Buttons

@docs radio, radioRow, Option, option, optionWith, OptionState


## Labels

@docs Label, labelAbove, labelBelow, labelLeft, labelRight, labelHidden

@docs focusedOnLoad

-}

import Element exposing (Attribute, Color, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Region as Region
import Html
import Html.Attributes
import Html.Events
import Internal.Flag as Flag
import Internal.Model as Internal
import Internal.Style exposing (classes)
import Json.Decode as Json


{-| -}
type Placeholder msg
    = Placeholder (List (Attribute msg)) (Element msg)


white =
    Element.rgb 1 1 1


darkGrey =
    Element.rgb (186 / 255) (189 / 255) (182 / 255)


charcoal =
    Element.rgb
        (136 / 255)
        (138 / 255)
        (133 / 255)


{-| -}
placeholder : List (Attribute msg) -> Element msg -> Placeholder msg
placeholder =
    Placeholder


type LabelLocation
    = OnRight
    | OnLeft
    | Above
    | Below


{-| Every input has a required `label`.
-}
type Label msg
    = Label LabelLocation (List (Attribute msg)) (Element msg)
    | HiddenLabel String


{-| -}
labelRight : List (Attribute msg) -> Element msg -> Label msg
labelRight =
    Label OnRight


{-| -}
labelLeft : List (Attribute msg) -> Element msg -> Label msg
labelLeft =
    Label OnLeft


{-| -}
labelAbove : List (Attribute msg) -> Element msg -> Label msg
labelAbove =
    Label Above


{-| -}
labelBelow : List (Attribute msg) -> Element msg -> Label msg
labelBelow =
    Label Below


{-| Sometimes you may need to have a label which is not visible, but is still accessible to screen readers.

Seriously consider a visible label before using this.

The situations where a hidden label makes sense:

  - A searchbar with a `search` button right next to it.
  - A `table` of inputs where the header gives the label.

Basically, a hidden label works when there are other contextual clues that sighted people can pick up on.

-}
labelHidden : String -> Label msg
labelHidden =
    HiddenLabel


hiddenLabelAttribute label =
    case label of
        HiddenLabel textLabel ->
            Internal.Describe (Internal.Label textLabel)

        Label _ _ _ ->
            Internal.NoAttribute


{-| A standard button.

The `onPress` handler will be fired either `onClick` or when the element is focused and the enter key has been pressed.

    import Element.Input as Input

    Input.button []
        { onPress = ClickMsg
        , label = text "My Button"
        }

`onPress` takes a `Maybe msg`. If you provide the value `Nothing`, then the button will be disabled.

-}
button :
    List (Attribute msg)
    ->
        { onPress : Maybe msg
        , label : Element msg
        }
    -> Element msg
button attrs { onPress, label } =
    Internal.element
        Internal.asEl
        -- We don't explicitly label this node as a button,
        -- because buttons fire a bunch of times when you hold down the enter key.
        -- We'd like to fire just once on the enter key, which means using keyup instead of keydown.
        -- Because we have no way to disable keydown, though our messages get doubled.
        Internal.div
        (Element.width Element.shrink
            :: Element.height Element.shrink
            :: Internal.htmlClass
                (classes.contentCenterX
                    ++ " "
                    ++ classes.contentCenterY
                    ++ " "
                    ++ classes.seButton
                    ++ " "
                    ++ classes.noTextSelection
                )
            :: Element.pointer
            :: focusDefault attrs
            :: Internal.Describe Internal.Button
            :: Internal.Attr (Html.Attributes.tabindex 0)
            :: (case onPress of
                    Nothing ->
                        Internal.Attr (Html.Attributes.disabled True) :: attrs

                    Just msg ->
                        Events.onClick msg
                            :: onEnter msg
                            :: attrs
               )
        )
        (Internal.Unkeyed [ label ])


focusDefault attrs =
    if List.any hasFocusStyle attrs then
        Internal.NoAttribute

    else
        Internal.htmlClass "focusable"


hasFocusStyle attr =
    case attr of
        Internal.StyleClass _ (Internal.PseudoSelector Internal.Focus _) ->
            True

        _ ->
            False


{-| -}
type alias Checkbox msg =
    { onChange : Maybe (Bool -> msg)
    , icon : Maybe (Element msg)
    , checked : Bool
    , label : Label msg
    }


{-| -}
checkbox :
    List (Attribute msg)
    ->
        { onChange : Bool -> msg
        , icon : Bool -> Element msg
        , checked : Bool
        , label : Label msg
        }
    -> Element msg
checkbox attrs { label, icon, checked, onChange } =
    let
        attributes =
            [ if isHiddenLabel label then
                Internal.NoAttribute

              else
                Element.spacing
                    6
            , Internal.Attr (Html.Events.onClick (onChange (not checked)))
            , Region.announce
            , onKeyLookup <|
                \code ->
                    if code == enter then
                        Just <| onChange (not checked)

                    else if code == space then
                        Just <| onChange (not checked)

                    else
                        Nothing
            , tabindex 0
            , Element.pointer
            , Element.alignLeft
            , Element.width Element.fill
            ]
                ++ attrs
    in
    applyLabel attributes
        label
        (Internal.element
            Internal.asEl
            Internal.div
            [ Internal.Attr <|
                Html.Attributes.attribute "role" "checkbox"
            , Internal.Attr <|
                Html.Attributes.attribute "aria-checked" <|
                    if checked then
                        "true"

                    else
                        "false"
            , hiddenLabelAttribute label
            , Element.centerY
            , Element.height Element.fill
            , Element.width Element.shrink
            ]
            (Internal.Unkeyed
                [ icon checked
                ]
            )
        )


{-| -}
type Thumb
    = Thumb (List (Attribute Never))


{-| -}
thumb : List (Attribute Never) -> Thumb
thumb =
    Thumb


{-| -}
defaultThumb : Thumb
defaultThumb =
    Thumb
        [ Element.width (Element.px 16)
        , Element.height (Element.px 16)
        , Border.rounded 8
        , Border.width 1
        , Border.color (Element.rgb 0.5 0.5 0.5)
        , Background.color (Element.rgb 1 1 1)
        ]


{-| A slider input, good for capturing float values.

    Input.slider
        [ Element.height (Element.px 30)

        -- Here is where we're creating/styling the "track"
        , Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color grey
                , Border.rounded 2
                ]
                Element.none
            )
        ]
        { onChange = AdjustValue
        , label = Input.labelAbove [] (text "My Slider Value")
        , min = 0
        , max = 75
        , step = Nothing
        , value = model.sliderValue
        , thumb =
            Input.defaultThumb
        }

`Element.behindContent` is used to render the track of the slider. Without it, no track would be rendered. The `thumb` is the icon that you can move around.

The slider can be vertical or horizontal depending on the width/height of the slider.

  - `height fill` and `width (px someWidth)` will cause the slider to be vertical.
  - `height (px someHeight)` and `width (px someWidth)` where `someHeight` > `someWidth` will also do it.
  - otherwise, the slider will be horizontal.

**Note:** If you want a slider for an `Int` value:

  - set `step` to be `Just 1`, or some other whole value
  - `value = toFloat model.myInt`
  - And finally, round the value before making a message `onChange = round >> AdjustValue`

-}
slider :
    List (Attribute msg)
    ->
        { onChange : Float -> msg
        , label : Label msg
        , min : Float
        , max : Float
        , value : Float
        , thumb : Thumb
        , step : Maybe Float
        }
    -> Element msg
slider attributes input =
    let
        (Thumb thumbAttributes) =
            input.thumb

        width =
            Internal.getWidth thumbAttributes

        height =
            Internal.getHeight thumbAttributes

        vertical =
            case ( trackWidth, trackHeight ) of
                ( Nothing, Nothing ) ->
                    False

                ( Just (Internal.Px w), Just (Internal.Px h) ) ->
                    h > w

                ( Just (Internal.Px _), Just (Internal.Fill _) ) ->
                    True

                _ ->
                    False

        trackHeight =
            Internal.getHeight attributes

        trackWidth =
            Internal.getWidth attributes

        ( spacingX, spacingY ) =
            Internal.getSpacing attributes ( 5, 5 )

        factor =
            (input.value - input.min)
                / (input.max - input.min)

        {- Needed attributes

           Thumb Attributes
              - Width/Height of thumb so that the input can shadow it.


           Attributes

               OnParent ->
                   Spacing


               On track ->
                   Everything else




            The `<input>`


        -}
        className =
            "thmb-" ++ thumbWidthString ++ "-" ++ thumbHeightString

        thumbWidthString =
            case width of
                Nothing ->
                    "20px"

                Just (Internal.Px px) ->
                    String.fromInt px ++ "px"

                _ ->
                    "100%"

        thumbHeightString =
            case height of
                Nothing ->
                    "20px"

                Just (Internal.Px px) ->
                    String.fromInt px ++ "px"

                _ ->
                    "100%"

        thumbShadowStyle =
            [ Internal.Property "width"
                thumbWidthString
            , Internal.Property "height"
                thumbHeightString
            ]
    in
    applyLabel
        [ if isHiddenLabel input.label then
            Internal.NoAttribute

          else
            Element.spacingXY spacingX spacingY
        , Region.announce
        , Element.width
            (case trackWidth of
                Nothing ->
                    Element.fill

                Just (Internal.Px _) ->
                    Element.shrink

                Just x ->
                    x
            )
        , Element.height
            (case trackHeight of
                Nothing ->
                    Element.shrink

                Just (Internal.Px _) ->
                    Element.shrink

                Just x ->
                    x
            )
        ]
        input.label
        (Element.row
            [ Element.width
                (Maybe.withDefault Element.fill trackWidth)
            , Element.height
                (Maybe.withDefault (Element.px 20) trackHeight)
            ]
            [ Internal.element
                Internal.asEl
                (Internal.NodeName "input")
                [ hiddenLabelAttribute input.label
                , Internal.StyleClass Flag.active
                    (Internal.Style
                        ("input[type=\"range\"]." ++ className ++ "::-moz-range-thumb")
                        thumbShadowStyle
                    )
                , Internal.StyleClass Flag.hover
                    (Internal.Style
                        ("input[type=\"range\"]." ++ className ++ "::-webkit-slider-thumb")
                        thumbShadowStyle
                    )
                , Internal.StyleClass Flag.focus
                    (Internal.Style
                        ("input[type=\"range\"]." ++ className ++ "::-ms-thumb")
                        thumbShadowStyle
                    )
                , Internal.Attr (Html.Attributes.class (className ++ " focusable-parent"))
                , Internal.Attr
                    (Html.Events.onInput
                        (\str ->
                            case String.toFloat str of
                                Nothing ->
                                    -- This should never happen because the browser
                                    -- should always provide a Float.
                                    input.onChange 0

                                Just val ->
                                    input.onChange val
                        )
                    )
                , Internal.Attr <|
                    Html.Attributes.type_ "range"
                , Internal.Attr <|
                    Html.Attributes.step
                        (case input.step of
                            Nothing ->
                                -- Note: If we set `any` here,
                                -- Firefox makes a single press of the arrows keys equal to 1
                                -- We could set the step manually to the effective range / 100
                                -- String.fromFloat ((input.max - input.min) / 100)
                                -- Which matches Chrome's default behavior
                                -- HOWEVER, that means manually moving a slider with the mouse will snap to that interval.
                                "any"

                            Just step ->
                                String.fromFloat step
                        )
                , Internal.Attr <|
                    Html.Attributes.min (String.fromFloat input.min)
                , Internal.Attr <|
                    Html.Attributes.max (String.fromFloat input.max)
                , Internal.Attr <|
                    Html.Attributes.value (String.fromFloat input.value)
                , if vertical then
                    Internal.Attr <|
                        Html.Attributes.attribute "orient" "vertical"

                  else
                    Internal.NoAttribute
                , Element.width <|
                    if vertical then
                        Maybe.withDefault (Element.px 20) trackHeight

                    else
                        Maybe.withDefault Element.fill trackWidth
                , Element.height <|
                    if vertical then
                        Maybe.withDefault Element.fill trackWidth

                    else
                        Maybe.withDefault (Element.px 20) trackHeight
                ]
                (Internal.Unkeyed [])
            , Element.el
                (Element.width
                    (Maybe.withDefault Element.fill trackWidth)
                    :: Element.height
                        (Maybe.withDefault (Element.px 20) trackHeight)
                    :: attributes
                    -- This is after `attributes` because the thumb should be in front of everything.
                    ++ [ Element.behindContent <|
                            if vertical then
                                viewVerticalThumb factor thumbAttributes trackWidth

                            else
                                viewHorizontalThumb factor thumbAttributes trackHeight
                       ]
                )
                Element.none
            ]
        )


viewHorizontalThumb factor thumbAttributes trackHeight =
    Element.row
        [ Element.width Element.fill
        , Element.height (Maybe.withDefault Element.fill trackHeight)
        , Element.centerY
        ]
        [ Element.el
            [ Element.width (Element.fillPortion (round <| factor * 10000))
            ]
            Element.none
        , Element.el
            (Element.centerY
                :: List.map (Internal.mapAttr Basics.never) thumbAttributes
            )
            Element.none
        , Element.el
            [ Element.width (Element.fillPortion (round <| (abs <| 1 - factor) * 10000))
            ]
            Element.none
        ]


viewVerticalThumb factor thumbAttributes trackWidth =
    Element.column
        [ Element.height Element.fill
        , Element.width (Maybe.withDefault Element.fill trackWidth)
        , Element.centerX
        ]
        [ Element.el
            [ Element.height (Element.fillPortion (round <| (abs <| 1 - factor) * 10000))
            ]
            Element.none
        , Element.el
            (Element.centerX
                :: List.map (Internal.mapAttr Basics.never) thumbAttributes
            )
            Element.none
        , Element.el
            [ Element.height (Element.fillPortion (round <| factor * 10000))
            ]
            Element.none
        ]


type alias TextInput =
    { type_ : TextKind
    , spellchecked : Bool
    , autofill : Maybe String
    }


type TextKind
    = TextInputNode String
    | TextArea


{-| -}
type alias Text msg =
    { onChange : String -> msg
    , text : String
    , placeholder : Maybe (Placeholder msg)
    , label : Label msg
    }


{-| -}
textHelper : TextInput -> List (Attribute msg) -> Text msg -> Element msg
textHelper textInput attrs textOptions =
    let
        withDefaults =
            defaultTextBoxStyle ++ attrs

        redistributed =
            redistribute withDefaults

        moveUpToCompensateForPadding =
            calcMoveToCompensateForPadding withDefaults

        onlySpacing attr =
            case attr of
                Internal.StyleClass _ (Internal.SpacingStyle _ _ _) ->
                    True

                _ ->
                    False

        isHeightContent attr =
            case attr of
                Internal.Height Internal.Content ->
                    True

                _ ->
                    False

        bottomPadding attr =
            case attr of
                Internal.StyleClass cls (Internal.PaddingStyle pad t r b l) ->
                    Just <|
                        Element.paddingEach
                            { top = 0
                            , right = 0
                            , bottom = b
                            , left = 0
                            }

                _ ->
                    Nothing

        heightContent =
            case textInput.type_ of
                TextInputNode inputType ->
                    False

                TextArea ->
                    List.any isHeightContent withDefaults

        inputElement =
            Internal.element
                Internal.asEl
                (case textInput.type_ of
                    TextInputNode inputType ->
                        Internal.NodeName "input"

                    TextArea ->
                        Internal.NodeName "textarea"
                )
                ([ value textOptions.text
                 , Internal.Attr (Html.Events.onInput textOptions.onChange)
                 , hiddenLabelAttribute textOptions.label
                 , spellcheck textInput.spellchecked
                 , Maybe.map autofill textInput.autofill
                    |> Maybe.withDefault Internal.NoAttribute
                 ]
                    ++ (case textInput.type_ of
                            TextInputNode inputType ->
                                [ Internal.Attr (Html.Attributes.type_ inputType)
                                , Internal.htmlClass classes.inputText
                                , Internal.htmlClass "focusable"
                                ]

                            TextArea ->
                                [ Element.clip
                                , Element.height Element.fill
                                , Internal.htmlClass classes.inputMultiline
                                , Element.alpha 0.3
                                , moveUpToCompensateForPadding
                                ]
                       )
                    ++ redistributed.input
                )
                (Internal.Unkeyed [])

        wrappedInput =
            -- if heightContent  then
            case textInput.type_ of
                TextArea ->
                    -- textarea with height-content means that
                    -- the input element is rendered `inFront` and transparently.
                    -- Then the input text is rendered as the actual element.
                    Internal.element
                        Internal.asEl
                        Internal.div
                        ([ Element.width Element.fill
                         , Element.height (Element.px 100)
                         , Element.scrollbarY
                         , Internal.htmlClass classes.focusedWithin
                         ]
                            ++ redistributed.parent
                        )
                        (Internal.Unkeyed
                            [ Internal.element
                                Internal.asParagraph
                                Internal.div
                                (Element.width Element.fill
                                    :: Element.height Element.fill
                                    :: Element.inFront inputElement
                                    :: Internal.htmlClass classes.inputMultiline
                                    :: List.concat
                                        [ if heightContent then
                                            redistributed.wrapper

                                          else
                                            redistributed.wrapper
                                                ++ List.filterMap bottomPadding redistributed.parent
                                        , case textOptions.placeholder of
                                            Nothing ->
                                                []

                                            Just place ->
                                                [ renderPlaceholder place redistributed.cover (textOptions.text == "")
                                                ]
                                        ]
                                )
                                (Internal.Unkeyed
                                    [ Internal.unstyled (Html.text textOptions.text) ]
                                )
                            ]
                        )

                TextInputNode inputType ->
                    Internal.element
                        Internal.asEl
                        Internal.div
                        (Element.width Element.fill
                            :: List.concat
                                [ redistributed.parent
                                , case textOptions.placeholder of
                                    Nothing ->
                                        []

                                    Just place ->
                                        [ renderPlaceholder place redistributed.cover (textOptions.text == "")
                                        ]
                                ]
                        )
                        (Internal.Unkeyed [ inputElement ])
    in
    applyLabel
        (Internal.Class Flag.cursor classes.cursorText
            :: (if isHiddenLabel textOptions.label then
                    Internal.NoAttribute

                else
                    Element.spacing
                        5
               )
            :: Region.announce
            :: redistributed.fullParent
        )
        textOptions.label
        wrappedInput


renderPlaceholder (Placeholder placeholderAttrs placeholderEl) forPlaceholder on =
    Element.inFront
        (Element.el
            (defaultTextPadding
                :: forPlaceholder
                ++ [ Font.color charcoal
                   , Internal.htmlClass (classes.noTextSelection ++ " " ++ classes.passPointerEvents)
                   , Border.color (Element.rgba 0 0 0 0)
                   , Background.color (Element.rgba 0 0 0 0)
                   , Element.height Element.fill
                   , Element.width Element.fill
                   , Element.alpha
                        (if on then
                            1

                         else
                            0
                        )
                   ]
                ++ placeholderAttrs
            )
            placeholderEl
        )


{-| Because textareas are now shadowed, where they're rendered twice,
we to move the literal text area up because spacing is based on line height.
-}
calcMoveToCompensateForPadding : List (Attribute msg) -> Attribute msg
calcMoveToCompensateForPadding attrs =
    let
        gatherSpacing attr found =
            case attr of
                Internal.StyleClass _ (Internal.SpacingStyle _ x y) ->
                    case found of
                        Nothing ->
                            Just y

                        _ ->
                            found

                _ ->
                    found
    in
    case List.foldr gatherSpacing Nothing attrs of
        Nothing ->
            Internal.NoAttribute

        Just vSpace ->
            Element.moveUp (toFloat vSpace / 2)


{-| Given the list of attributes provided to `Input.multiline` or `Input.text`,

redistribute them to the parent, the input, or the cover.

  - fullParent -> Wrapper around label and input
  - parent -> parent of wrapper
  - wrapper -> the element that is here to take up space.
  - cover -> things like placeholders or text areas which are layered on top of input.
  - input -> actual input element

-}
redistribute :
    List (Attribute msg)
    ->
        { fullParent : List (Attribute msg)
        , parent : List (Attribute msg)
        , wrapper : List (Attribute msg)
        , input : List (Attribute msg)
        , cover : List (Attribute msg)
        }
redistribute attrs =
    List.foldl redistributeOver
        { fullParent = []
        , parent = []
        , input = []
        , cover = []
        , wrapper = []
        }
        attrs
        |> (\redist ->
                { parent = List.reverse redist.parent
                , fullParent = List.reverse redist.fullParent
                , wrapper = List.reverse redist.wrapper
                , input = List.reverse redist.input
                , cover = List.reverse redist.cover
                }
           )


redistributeOver attr els =
    case attr of
        Internal.Nearby _ _ ->
            { els | parent = attr :: els.parent }

        Internal.Width (Internal.Fill _) ->
            { els | fullParent = attr :: els.fullParent }

        Internal.Width _ ->
            { els | parent = attr :: els.parent }

        Internal.Height (Internal.Fill _) ->
            { els
                | fullParent = attr :: els.fullParent
                , parent = attr :: els.parent
            }

        Internal.Height h ->
            { els
                | parent = attr :: els.parent
            }

        Internal.AlignX _ ->
            { els | fullParent = attr :: els.fullParent }

        Internal.AlignY _ ->
            { els | fullParent = attr :: els.fullParent }

        Internal.StyleClass _ (Internal.SpacingStyle _ _ _) ->
            { els
                | fullParent = attr :: els.fullParent
                , parent = attr :: els.parent
                , input = attr :: els.input
                , wrapper = attr :: els.wrapper
            }

        Internal.StyleClass _ (Internal.PaddingStyle _ _ _ _ _) ->
            { els
                | parent = attr :: els.parent

                --   input = attr :: els.input
                -- , wrapper = attr :: els.wrapper
                , cover = attr :: els.cover
            }

        Internal.StyleClass _ (Internal.BorderWidth _ _ _ _ _) ->
            { els
                | parent = attr :: els.parent
                , cover = attr :: els.cover
            }

        Internal.StyleClass _ (Internal.Transform _) ->
            { els
                | parent = attr :: els.parent
                , cover = attr :: els.cover
            }

        Internal.StyleClass _ (Internal.FontSize _) ->
            { els | fullParent = attr :: els.fullParent }

        Internal.StyleClass _ (Internal.FontFamily _ _) ->
            { els | fullParent = attr :: els.fullParent }

        Internal.StyleClass _ _ ->
            { els | parent = attr :: els.parent }

        Internal.NoAttribute ->
            els

        Internal.Attr a ->
            { els | input = attr :: els.input }

        Internal.Describe _ ->
            { els | input = attr :: els.input }

        Internal.Class _ _ ->
            { els | parent = attr :: els.parent }

        Internal.TransformComponent _ _ ->
            { els | input = attr :: els.input }


orElse thing maybe =
    case maybe of
        Nothing ->
            Just thing

        _ ->
            maybe


inheritablePlaceholderAttributes attr =
    case attr of
        Internal.StyleClass _ (Internal.PaddingStyle _ _ _ _ _) ->
            True

        Internal.StyleClass _ (Internal.BorderWidth _ _ _ _ _) ->
            True

        Internal.StyleClass _ (Internal.Transform _) ->
            True

        _ ->
            False


{-| -}
text :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        }
    -> Element msg
text =
    textHelper
        { type_ = TextInputNode "text"
        , spellchecked = False
        , autofill = Nothing
        }


{-| If spell checking is available, this input will be spellchecked.
-}
spellChecked :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        }
    -> Element msg
spellChecked =
    textHelper
        { type_ = TextInputNode "text"
        , spellchecked = True
        , autofill = Nothing
        }


{-| -}
search :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        }
    -> Element msg
search =
    textHelper
        { type_ = TextInputNode "search"
        , spellchecked = False
        , autofill = Nothing
        }


{-| A password input that allows the browser to autofill.

It's `newPassword` instead of just `password` because it gives the browser a hint on what type of password input it is.

A password takes all the arguments a normal `Input.text` would, and also `show`, which will remove the password mask (e.g. `****` vs `pass1234`)

-}
newPassword :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        , show : Bool
        }
    -> Element msg
newPassword attrs pass =
    textHelper
        { type_ =
            TextInputNode <|
                if pass.show then
                    "text"

                else
                    "password"
        , spellchecked = False
        , autofill = Just "new-password"
        }
        attrs
        { onChange = pass.onChange
        , text = pass.text
        , placeholder = pass.placeholder
        , label = pass.label
        }


{-| -}
currentPassword :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        , show : Bool
        }
    -> Element msg
currentPassword attrs pass =
    textHelper
        { type_ =
            TextInputNode <|
                if pass.show then
                    "text"

                else
                    "password"
        , spellchecked = False
        , autofill = Just "current-password"
        }
        attrs
        { onChange = pass.onChange
        , text = pass.text
        , placeholder = pass.placeholder
        , label = pass.label
        }


{-| -}
username :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        }
    -> Element msg
username =
    textHelper
        { type_ = TextInputNode "text"
        , spellchecked = False
        , autofill = Just "username"
        }


{-| -}
email :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        }
    -> Element msg
email =
    textHelper
        { type_ = TextInputNode "email"
        , spellchecked = False
        , autofill = Just "email"
        }


{-| -}
multiline :
    List (Attribute msg)
    ->
        { onChange : String -> msg
        , text : String
        , placeholder : Maybe (Placeholder msg)
        , label : Label msg
        , spellcheck : Bool
        }
    -> Element msg
multiline attrs multi =
    textHelper
        { type_ =
            TextArea
        , spellchecked = multi.spellcheck
        , autofill = Nothing
        }
        attrs
        { onChange = multi.onChange
        , text = multi.text
        , placeholder = multi.placeholder
        , label = multi.label
        }


isHiddenLabel label =
    case label of
        HiddenLabel _ ->
            True

        _ ->
            False


applyLabel : List (Attribute msg) -> Label msg -> Element msg -> Element msg
applyLabel attrs label input =
    case label of
        HiddenLabel labelText ->
            -- NOTE: This means that the label is applied outside of this function!
            -- It would be nice to unify this logic, but it's a little tricky
            Internal.element
                Internal.asColumn
                (Internal.NodeName "label")
                attrs
                (Internal.Unkeyed [ input ])

        Label position labelAttrs labelChild ->
            let
                labelElement =
                    Internal.element
                        Internal.asEl
                        Internal.div
                        labelAttrs
                        (Internal.Unkeyed [ labelChild ])
            in
            case position of
                Above ->
                    Internal.element
                        Internal.asColumn
                        (Internal.NodeName "label")
                        attrs
                        (Internal.Unkeyed [ labelElement, input ])

                Below ->
                    Internal.element
                        Internal.asColumn
                        (Internal.NodeName "label")
                        attrs
                        (Internal.Unkeyed [ input, labelElement ])

                OnRight ->
                    Internal.element
                        Internal.asRow
                        (Internal.NodeName "label")
                        attrs
                        (Internal.Unkeyed [ input, labelElement ])

                OnLeft ->
                    Internal.element
                        Internal.asRow
                        (Internal.NodeName "label")
                        attrs
                        (Internal.Unkeyed [ labelElement, input ])


{-| Add choices to your radio and select menus.
-}
type Option value msg
    = Option value (OptionState -> Element msg)


{-| -}
type OptionState
    = Idle
    | Focused
    | Selected


{-| -}
option : value -> Element msg -> Option value msg
option val txt =
    Option val (defaultRadioOption txt)


{-| -}
optionWith : value -> (OptionState -> Element msg) -> Option value msg
optionWith val view =
    Option val view


{-|

    Input.radio
        [ padding 10
        , spacing 20
        ]
        { onChange = ChooseLunch
        , selected = Just model.lunch
        , label = Input.labelAbove [] (text "Lunch")
        , options =
            [ Input.option Burrito (text "Burrito")
            , Input.option Taco (text "Taco!")
            , Input.option Gyro (text "Gyro")
            ]
        }

-}
radio :
    List (Attribute msg)
    ->
        { onChange : option -> msg
        , options : List (Option option msg)
        , selected : Maybe option
        , label : Label msg
        }
    -> Element msg
radio =
    radioHelper Column


{-| Same as radio, but displayed as a row
-}
radioRow :
    List (Attribute msg)
    ->
        { onChange : option -> msg
        , options : List (Option option msg)
        , selected : Maybe option
        , label : Label msg
        }
    -> Element msg
radioRow =
    radioHelper Row


defaultRadioOption : Element msg -> OptionState -> Element msg
defaultRadioOption optionLabel status =
    Element.row
        [ Element.spacing 10
        , Element.alignLeft
        , Element.width Element.shrink
        ]
        [ Element.el
            [ Element.width (Element.px 14)
            , Element.height (Element.px 14)
            , Background.color white
            , Border.rounded 7
            , case status of
                Selected ->
                    Internal.htmlClass "focusable"

                _ ->
                    Internal.NoAttribute

            -- , Border.shadow <|
            --     -- case status of
            --     --     Idle ->
            --     --         { offset = ( 0, 0 )
            --     --         , blur =
            --     --             1
            --     --         , color = Color.rgb 235 235 235
            --     --         }
            --     --     Focused ->
            --     --         { offset = ( 0, 0 )
            --     --         , blur =
            --     --             0
            --     --         , color = Color.rgba 235 235 235 0
            --     --         }
            --     --     Selected ->
            --     { offset = ( 0, 0 )
            --     , blur =
            --         1
            --     , color = Color.rgba 235 235 235 0
            --     }
            , Border.width <|
                case status of
                    Idle ->
                        1

                    Focused ->
                        1

                    Selected ->
                        5
            , Border.color <|
                case status of
                    Idle ->
                        Element.rgb (208 / 255) (208 / 255) (208 / 255)

                    Focused ->
                        Element.rgb (208 / 255) (208 / 255) (208 / 255)

                    Selected ->
                        Element.rgb (59 / 255) (153 / 255) (252 / 255)
            ]
            Element.none
        , Element.el [ Element.width Element.fill, Internal.htmlClass "unfocusable" ] optionLabel
        ]


radioHelper :
    Orientation
    -> List (Attribute msg)
    ->
        { onChange : option -> msg
        , options : List (Option option msg)
        , selected : Maybe option
        , label : Label msg
        }
    -> Element msg
radioHelper orientation attrs input =
    let
        renderOption (Option val view) =
            let
                status =
                    if Just val == input.selected then
                        Selected

                    else
                        Idle
            in
            Element.el
                [ Element.pointer
                , case orientation of
                    Row ->
                        Element.width Element.shrink

                    Column ->
                        Element.width Element.fill
                , Events.onClick (input.onChange val)
                , case status of
                    Selected ->
                        Internal.Attr <|
                            Html.Attributes.attribute "aria-checked"
                                "true"

                    _ ->
                        Internal.Attr <|
                            Html.Attributes.attribute "aria-checked"
                                "false"
                , Internal.Attr <|
                    Html.Attributes.attribute "role" "radio"
                ]
                (view status)

        optionArea =
            case orientation of
                Row ->
                    row (hiddenLabelAttribute input.label :: attrs)
                        (List.map renderOption input.options)

                Column ->
                    column (hiddenLabelAttribute input.label :: attrs)
                        (List.map renderOption input.options)

        prevNext =
            case input.options of
                [] ->
                    Nothing

                (Option val _) :: _ ->
                    List.foldl track ( NotFound, val, val ) input.options
                        |> (\( found, b, a ) ->
                                case found of
                                    NotFound ->
                                        Just ( b, val )

                                    BeforeFound ->
                                        Just ( b, val )

                                    _ ->
                                        Just ( b, a )
                           )

        track opt ( found, prev, nxt ) =
            case opt of
                Option val _ ->
                    case found of
                        NotFound ->
                            if Just val == input.selected then
                                ( BeforeFound, prev, nxt )

                            else
                                ( found, val, nxt )

                        BeforeFound ->
                            ( AfterFound, prev, val )

                        AfterFound ->
                            ( found, prev, nxt )

        events =
            Internal.get
                attrs
            <|
                \attr ->
                    case attr of
                        Internal.Width (Internal.Fill _) ->
                            True

                        Internal.Height (Internal.Fill _) ->
                            True

                        Internal.Attr _ ->
                            True

                        _ ->
                            False
    in
    applyLabel
        (List.filterMap identity
            [ Just Element.alignLeft
            , Just (tabindex 0)
            , Just (Internal.htmlClass "focus")
            , Just Region.announce
            , Just <|
                Internal.Attr <|
                    Html.Attributes.attribute "role" "radiogroup"
            , case prevNext of
                Nothing ->
                    Nothing

                Just ( prev, next ) ->
                    Just
                        (onKeyLookup <|
                            \code ->
                                if code == leftArrow then
                                    Just (input.onChange prev)

                                else if code == upArrow then
                                    Just (input.onChange prev)

                                else if code == rightArrow then
                                    Just (input.onChange next)

                                else if code == downArrow then
                                    Just (input.onChange next)

                                else if code == space then
                                    case input.selected of
                                        Nothing ->
                                            Just (input.onChange prev)

                                        _ ->
                                            Nothing

                                else
                                    Nothing
                        )
            ]
            ++ events
         -- ++ hideIfEverythingisInvisible
        )
        input.label
        optionArea


type Found
    = NotFound
    | BeforeFound
    | AfterFound


type Orientation
    = Row
    | Column


column : List (Attribute msg) -> List (Internal.Element msg) -> Internal.Element msg
column attributes children =
    Internal.element
        Internal.asColumn
        Internal.div
        (Element.height Element.shrink
            :: Element.width Element.fill
            :: attributes
        )
        (Internal.Unkeyed children)


row : List (Attribute msg) -> List (Internal.Element msg) -> Internal.Element msg
row attributes children =
    Internal.element
        Internal.asRow
        Internal.div
        (Element.width Element.fill
            :: attributes
        )
        (Internal.Unkeyed children)



{- Event Handlers -}


{-| -}
onEnter : msg -> Attribute msg
onEnter msg =
    onKey enter msg


{-| -}
onSpace : msg -> Attribute msg
onSpace msg =
    onKey space msg


{-| -}
onUpArrow : msg -> Attribute msg
onUpArrow msg =
    onKey upArrow msg


{-| -}
onRightArrow : msg -> Attribute msg
onRightArrow msg =
    onKey rightArrow msg


{-| -}
onLeftArrow : msg -> Attribute msg
onLeftArrow msg =
    onKey leftArrow msg


{-| -}
onDownArrow : msg -> Attribute msg
onDownArrow msg =
    onKey downArrow msg


enter : String
enter =
    "Enter"


tab : String
tab =
    "Tab"


delete : String
delete =
    "Delete"


backspace : String
backspace =
    "Backspace"


upArrow : String
upArrow =
    "ArrowUp"


leftArrow : String
leftArrow =
    "ArrowLeft"


rightArrow : String
rightArrow =
    "ArrowRight"


downArrow : String
downArrow =
    "ArrowDown"


space : String
space =
    " "


{-| -}
onKey : String -> msg -> Attribute msg
onKey desiredCode msg =
    let
        decode code =
            if code == desiredCode then
                Json.succeed msg

            else
                Json.fail "Not the enter key"

        isKey =
            Json.field "key" Json.string
                |> Json.andThen decode
    in
    Internal.Attr <|
        Html.Events.preventDefaultOn "keyup"
            (Json.map (\fired -> ( fired, True )) isKey)



-- preventKeydown : String -> a -> Attribute a
-- preventKeydown desiredCode msg =
--     let
--         decode code =
--             if code == desiredCode then
--                 Json.succeed msg
--             else
--                 Json.fail "Not the enter key"
--         isKey =
--             Json.field "key" Json.string
--                 |> Json.andThen decode
--     in
--     Events.onWithOptions "keydown"
--         { stopPropagation = False
--         , preventDefault = True
--         }
--         isKey


{-| -}
onKeyLookup : (String -> Maybe msg) -> Attribute msg
onKeyLookup lookup =
    let
        decode code =
            case lookup code of
                Nothing ->
                    Json.fail "No key matched"

                Just msg ->
                    Json.succeed msg

        isKey =
            Json.field "key" Json.string
                |> Json.andThen decode
    in
    Internal.Attr <| Html.Events.on "keyup" isKey


{-| -}
onFocusOut : msg -> Attribute msg
onFocusOut msg =
    Internal.Attr <| Html.Events.on "focusout" (Json.succeed msg)


{-| -}
onFocusIn : msg -> Attribute msg
onFocusIn msg =
    Internal.Attr <| Html.Events.on "focusin" (Json.succeed msg)


type_ : String -> Attribute msg
type_ =
    Internal.Attr << Html.Attributes.type_



-- checked : Bool -> Attribute msg
-- checked =
--     Internal.Attr << Html.Attributes.checked


selected : Bool -> Attribute msg
selected =
    Internal.Attr << Html.Attributes.selected


name : String -> Attribute msg
name =
    Internal.Attr << Html.Attributes.name


value : String -> Attribute msg
value =
    Internal.Attr << Html.Attributes.value


tabindex : Int -> Attribute msg
tabindex =
    Internal.Attr << Html.Attributes.tabindex


disabled : Bool -> Attribute msg
disabled =
    Internal.Attr << Html.Attributes.disabled


spellcheck : Bool -> Attribute msg
spellcheck =
    Internal.Attr << Html.Attributes.spellcheck


readonly : Bool -> Attribute msg
readonly =
    Internal.Attr << Html.Attributes.readonly


autofill : String -> Attribute msg
autofill =
    Internal.Attr << Html.Attributes.attribute "autocomplete"


{-| -}
focusedOnLoad : Attribute msg
focusedOnLoad =
    Internal.Attr <| Html.Attributes.autofocus True



{- Style Defaults -}


defaultTextBoxStyle : List (Attribute msg)
defaultTextBoxStyle =
    [ defaultTextPadding
    , Border.rounded 3
    , Border.color darkGrey
    , Background.color white
    , Border.width 1
    , Element.spacing 3
    , Element.width Element.fill
    ]


defaultTextPadding : Attribute msg
defaultTextPadding =
    Element.paddingXY 12 12


{-| -}
defaultCheckbox : Bool -> Element msg
defaultCheckbox checked =
    Element.el
        [ Internal.htmlClass "focusable"
        , Element.width (Element.px 14)
        , Element.height (Element.px 14)
        , Font.color white
        , Element.centerY
        , Font.size 9
        , Font.center
        , Border.rounded 3
        , Border.color <|
            if checked then
                Element.rgb (59 / 255) (153 / 255) (252 / 255)

            else
                Element.rgb (211 / 255) (211 / 255) (211 / 255)
        , Border.shadow <|
            { offset = ( 0, 0 )
            , blur = 1
            , size = 1
            , color =
                if checked then
                    Element.rgba (238 / 255) (238 / 255) (238 / 255) 0

                else
                    Element.rgb (238 / 255) (238 / 255) (238 / 255)
            }
        , Background.color <|
            if checked then
                Element.rgb (59 / 255) (153 / 255) (252 / 255)

            else
                white
        , Border.width <|
            if checked then
                0

            else
                1
        ]
        (if checked then
            Element.el
                [ Border.color white
                , Element.height (Element.px 6)
                , Element.width (Element.px 9)
                , Element.rotate (degrees -45)
                , Element.centerX
                , Element.centerY
                , Element.moveUp 1
                , Border.widthEach
                    { top = 0
                    , left = 2
                    , bottom = 2
                    , right = 0
                    }
                ]
                Element.none

         else
            Element.none
        )
