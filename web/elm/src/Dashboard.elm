module Dashboard exposing
    ( Model
    , handleCallback
    , init
    , subscriptions
    , update
    , view
    )

import Array
import Callback exposing (Callback(..))
import Char
import Concourse
import Concourse.Cli as Cli
import Concourse.PipelineStatus as PipelineStatus exposing (PipelineStatus(..))
import Concourse.User
import Dashboard.APIData as APIData
import Dashboard.Footer as Footer
import Dashboard.Group as Group
import Dashboard.Models as Models
import Dashboard.Msgs as Msgs exposing (Msg(..))
import Dashboard.Styles as Styles
import Dashboard.SubState as SubState
import Dashboard.Text as Text
import Effects exposing (Effect(..))
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes
    exposing
        ( attribute
        , class
        , classList
        , css
        , draggable
        , href
        , id
        , src
        , style
        )
import Html.Styled.Events exposing (onMouseEnter, onMouseLeave)
import Http
import List.Extra
import NewTopBar
import Regex exposing (HowMany(All), regex, replace)
import RemoteData
import Routes
import ScreenSize
import SearchBar exposing (SearchBar(..))
import Simple.Fuzzy exposing (filter, match, root)
import Subscription exposing (Subscription(..))
import Task
import Time exposing (Time)
import UserState


type alias Flags =
    { csrfToken : String
    , turbulencePath : String
    , search : String
    , highDensity : Bool
    , pipelineRunningKeyframes : String
    }


type DashboardError
    = NotAsked
    | Turbulence String


type alias Model =
    { csrfToken : String
    , state : Result DashboardError SubState.SubState
    , turbulencePath : String
    , highDensity : Bool
    , hoveredPipeline : Maybe Models.Pipeline
    , pipelineRunningKeyframes : String
    , groups : List Group.Group
    , hoveredCliIcon : Maybe Cli.Cli
    , hoveredTopCliIcon : Maybe Cli.Cli
    , screenSize : ScreenSize.ScreenSize
    , version : String
    , userState : UserState.UserState
    , userMenuVisible : Bool
    , searchBar : SearchBar
    , hideFooter : Bool
    , hideFooterCounter : Int
    , showHelp : Bool
    , dragChanged : Bool
    }


init : Flags -> ( Model, List Effect )
init flags =
    let
        searchBar =
            Expanded
                { query = flags.search
                , selectionMade = False
                , showAutocomplete = False
                , selection = 0
                }
    in
    ( { state = Err NotAsked
      , csrfToken = flags.csrfToken
      , turbulencePath = flags.turbulencePath
      , highDensity = flags.highDensity
      , hoveredPipeline = Nothing
      , pipelineRunningKeyframes = flags.pipelineRunningKeyframes
      , groups = []
      , hoveredCliIcon = Nothing
      , hoveredTopCliIcon = Nothing
      , screenSize = ScreenSize.Desktop
      , version = ""
      , userState = UserState.UserStateUnknown
      , userMenuVisible = False
      , hideFooter = False
      , hideFooterCounter = 0
      , showHelp = False
      , searchBar = searchBar
      , dragChanged = False
      }
    , [ FetchData
      , PinTeamNames Group.stickyHeaderConfig
      , SetTitle <| "Dashboard" ++ " - "
      , GetScreenSize
      ]
    )


handleCallback : Callback -> Model -> ( Model, List Effect )
handleCallback msg model =
    case msg of
        APIDataFetched RemoteData.NotAsked ->
            ( { model | state = Err NotAsked }, [] )

        APIDataFetched RemoteData.Loading ->
            ( { model | state = Err NotAsked }, [] )

        APIDataFetched (RemoteData.Failure _) ->
            ( { model | state = Err (Turbulence model.turbulencePath) }, [] )

        APIDataFetched (RemoteData.Success ( now, apiData )) ->
            let
                groups =
                    Group.groups apiData

                noPipelines =
                    List.isEmpty <| List.concatMap .pipelines groups

                newModel =
                    case model.state of
                        Ok substate ->
                            { model
                                | state =
                                    Ok (SubState.tick now substate)
                            }

                        _ ->
                            { model
                                | state =
                                    Ok
                                        { now = now
                                        , dragState = Group.NotDragging
                                        }
                            }

                userState =
                    case apiData.user of
                        Just u ->
                            UserState.UserStateLoggedIn u

                        Nothing ->
                            UserState.UserStateLoggedOut
            in
            if model.highDensity && noPipelines then
                ( { newModel
                    | highDensity = False
                    , groups = groups
                    , version = apiData.version
                    , userState = userState
                  }
                , [ ModifyUrl Routes.dashboardRoute ]
                )

            else
                ( { newModel
                    | groups = groups
                    , version = apiData.version
                    , userState = userState
                  }
                , []
                )

        LoggedOut (Ok ()) ->
            let
                redirectUrl =
                    if model.highDensity then
                        Routes.dashboardHdRoute

                    else
                        Routes.dashboardRoute
            in
            ( { model
                | userState = UserState.UserStateLoggedOut
                , userMenuVisible = False
              }
            , [ NavigateTo redirectUrl, FetchData ]
            )

        LoggedOut (Err err) ->
            flip always (Debug.log "failed to log out" err) <|
                ( model, [] )

        ScreenResized size ->
            let
                newSize =
                    ScreenSize.fromWindowSize size
            in
            ( { model
                | screenSize = newSize
                , searchBar =
                    SearchBar.screenSizeChanged
                        { oldSize = model.screenSize
                        , newSize = newSize
                        }
                        model.searchBar
              }
            , []
            )

        _ ->
            ( model, [] )


update : Msg -> Model -> ( Model, List Effect )
update msg model =
    case msg of
        ClockTick now ->
            ( let
                newModel =
                    Footer.tick model
              in
              case model.state of
                Ok substate ->
                    { newModel | state = Ok (SubState.tick now substate) }

                _ ->
                    newModel
            , []
            )

        AutoRefresh _ ->
            ( model
            , [ FetchData ]
            )

        KeyPressed keycode ->
            handleKeyPressed (Char.fromCode keycode) model

        ShowFooter ->
            ( Footer.showFooter model, [] )

        TogglePipelinePaused pipeline ->
            ( model
            , [ SendTogglePipelineRequest
                    { pipeline = pipeline, csrfToken = model.csrfToken }
              ]
            )

        DragStart pid ->
            let
                group =
                    model.groups |> List.Extra.find (.teamName >> (==) pid.teamName)

                newModel =
                    case ( group, model.state ) of
                        ( Just g, Ok substate ) ->
                            { model
                                | state =
                                    Ok
                                        { substate
                                            | dragState = Group.startDrag g pid
                                        }
                            }

                        _ ->
                            model
            in
            ( newModel, [] )

        DragOver o ->
            let
                newModel =
                    case ( model.state, model.state |> Result.map .dragState ) of
                        ( Ok substate, Ok (Group.Dragging pid _) ) ->
                            { model
                                | state =
                                    Ok
                                        { substate
                                            | dragState =
                                                Group.Dragging
                                                    pid
                                                    o
                                        }
                                , dragChanged = True
                            }

                        _ ->
                            model
            in
            ( newModel, [] )

        TooltipHd pipelineName teamName ->
            ( model, [ ShowTooltipHd ( pipelineName, teamName ) ] )

        Tooltip pipelineName teamName ->
            ( model, [ ShowTooltip ( pipelineName, teamName ) ] )

        DragEnd ->
            let
                newModel =
                    case model.state of
                        Ok substate ->
                            let
                                newGroups =
                                    case substate.dragState of
                                        Group.NotDragging ->
                                            model.groups

                                        Group.Dragging pid over ->
                                            let
                                                tn =
                                                    pid.teamName

                                                pn =
                                                    pid.pipelineName
                                            in
                                            model.groups
                                                |> List.Extra.updateIf
                                                    (.teamName >> (==) tn)
                                                    (Group.drop
                                                        { pipelineName = pn
                                                        , over = over
                                                        }
                                                    )
                            in
                            { model
                                | state =
                                    Ok { substate | dragState = Group.NotDragging }
                                , groups = newGroups
                            }

                        _ ->
                            model
            in
            ( newModel, [] )

        PipelineButtonHover state ->
            ( { model | hoveredPipeline = state }, [] )

        CliHover state ->
            ( { model | hoveredCliIcon = state }, [] )

        TopCliHover state ->
            ( { model | hoveredTopCliIcon = state }, [] )

        FilterMsg query ->
            let
                newModel =
                    case model.searchBar of
                        Expanded r ->
                            { model | searchBar = Expanded { r | query = query } }

                        _ ->
                            model
            in
            ( newModel
            , [ FocusSearchInput, ModifyUrl (NewTopBar.queryStringFromSearch query) ]
            )

        LogIn ->
            ( model, [ RedirectToLogin ] )

        LogOut ->
            ( { model | state = Err NotAsked }, [ SendLogOutRequest ] )

        ToggleUserMenu ->
            ( { model | userMenuVisible = not model.userMenuVisible }, [] )

        FocusMsg ->
            let
                newModel =
                    case model.searchBar of
                        Expanded r ->
                            { model
                                | searchBar =
                                    Expanded
                                        { r
                                            | showAutocomplete = True
                                        }
                            }

                        _ ->
                            model
            in
            ( newModel, [] )

        BlurMsg ->
            let
                newModel =
                    case model.searchBar of
                        Expanded r ->
                            case model.screenSize of
                                ScreenSize.Mobile ->
                                    if String.isEmpty r.query then
                                        { model | searchBar = Collapsed }

                                    else
                                        { model
                                            | searchBar =
                                                Expanded
                                                    { r
                                                        | showAutocomplete = False
                                                        , selectionMade = False
                                                        , selection = 0
                                                    }
                                        }

                                ScreenSize.Desktop ->
                                    { model
                                        | searchBar =
                                            Expanded
                                                { r
                                                    | showAutocomplete = False
                                                    , selectionMade = False
                                                    , selection = 0
                                                }
                                    }

                                ScreenSize.BigDesktop ->
                                    { model
                                        | searchBar =
                                            Expanded
                                                { r
                                                    | showAutocomplete = False
                                                    , selectionMade = False
                                                    , selection = 0
                                                }
                                    }

                        _ ->
                            model
            in
            ( newModel, [] )

        SelectMsg index ->
            let
                newModel =
                    case model.searchBar of
                        Expanded r ->
                            { model
                                | searchBar =
                                    Expanded
                                        { r
                                            | selectionMade = True
                                            , selection = index + 1
                                        }
                            }

                        _ ->
                            model
            in
            ( newModel, [] )

        KeyDowns keycode ->
            case model.searchBar of
                Expanded r ->
                    if not r.showAutocomplete then
                        ( { model
                            | searchBar =
                                Expanded
                                    { r
                                        | selectionMade = False
                                        , selection = 0
                                    }
                          }
                        , []
                        )

                    else
                        case keycode of
                            -- enter key
                            13 ->
                                if not r.selectionMade then
                                    ( model, [] )

                                else
                                    let
                                        options =
                                            Array.fromList
                                                (NewTopBar.autocompleteOptions
                                                    { query = r.query
                                                    , groups = model.groups
                                                    }
                                                )

                                        index =
                                            (r.selection - 1) % Array.length options

                                        selectedItem =
                                            case Array.get index options of
                                                Nothing ->
                                                    r.query

                                                Just item ->
                                                    item
                                    in
                                    ( { model
                                        | searchBar =
                                            Expanded
                                                { r
                                                    | selectionMade = False
                                                    , selection = 0
                                                    , query = selectedItem
                                                }
                                      }
                                    , []
                                    )

                            -- up arrow
                            38 ->
                                ( { model
                                    | searchBar =
                                        Expanded
                                            { r
                                                | selectionMade = True
                                                , selection = r.selection - 1
                                            }
                                  }
                                , []
                                )

                            -- down arrow
                            40 ->
                                ( { model
                                    | searchBar =
                                        Expanded
                                            { r
                                                | selectionMade = True
                                                , selection = r.selection + 1
                                            }
                                  }
                                , []
                                )

                            -- escape key
                            27 ->
                                ( model, [ FocusSearchInput ] )

                            _ ->
                                ( { model
                                    | searchBar =
                                        Expanded
                                            { r
                                                | selectionMade = False
                                                , selection = 0
                                            }
                                  }
                                , []
                                )

                _ ->
                    ( model, [] )

        ShowSearchInput ->
            let
                newModel =
                    { model
                        | searchBar =
                            Expanded
                                { query = ""
                                , selectionMade = False
                                , showAutocomplete = False
                                , selection = 0
                                }
                    }
            in
            case model.searchBar of
                Collapsed ->
                    ( newModel, [ FocusSearchInput ] )

                _ ->
                    ( model, [] )

        ResizeScreen size ->
            let
                newSize =
                    ScreenSize.fromWindowSize size
            in
            ( { model
                | screenSize = newSize
                , searchBar =
                    SearchBar.screenSizeChanged
                        { oldSize = model.screenSize
                        , newSize = newSize
                        }
                        model.searchBar
              }
            , []
            )


subscriptions : Model -> List (Subscription Msg)
subscriptions model =
    [ OnClockTick Time.second ClockTick
    , OnClockTick (5 * Time.second) AutoRefresh
    , OnMouseMove ShowFooter
    , OnMouseClick ShowFooter
    , OnKeyPress KeyPressed
    , OnKeyDown KeyDowns
    , OnWindowResize Msgs.ResizeScreen
    ]


view : Model -> Html Msg
view model =
    Html.div
        [ class "page"
        , style
            [ ( "-webkit-font-smoothing", "antialiased" )
            , ( "font-weight", "700" )
            ]
        ]
        [ NewTopBar.view model
        , dashboardView model
        ]


dashboardView : Model -> Html Msg
dashboardView model =
    let
        mainContent =
            case model.state of
                Err NotAsked ->
                    [ Html.text "" ]

                Err (Turbulence path) ->
                    [ turbulenceView path ]

                Ok substate ->
                    [ Html.div
                        [ class "dashboard-content" ]
                      <|
                        welcomeCard model
                            ++ pipelinesView
                                { groups = model.groups
                                , substate = substate
                                , query = NewTopBar.query model
                                , hoveredPipeline = model.hoveredPipeline
                                , pipelineRunningKeyframes =
                                    model.pipelineRunningKeyframes
                                , userState = model.userState
                                , highDensity = model.highDensity
                                , dragChanged = model.dragChanged
                                }
                    ]
                        ++ (List.map Html.fromUnstyled <| Footer.view model)
    in
    Html.div
        [ classList
            [ ( .pageBodyClass Group.stickyHeaderConfig, True )
            , ( "dashboard-hd", model.highDensity )
            ]
        ]
        mainContent


welcomeCard :
    { a
        | hoveredTopCliIcon : Maybe Cli.Cli
        , groups : List Group.Group
        , userState : UserState.UserState
    }
    -> List (Html Msg)
welcomeCard { hoveredTopCliIcon, groups, userState } =
    let
        noPipelines =
            List.isEmpty (groups |> List.concatMap .pipelines)

        cliIcon : Maybe Cli.Cli -> Cli.Cli -> Html Msg
        cliIcon hoveredTopCliIcon cli =
            Html.a
                [ href (Cli.downloadUrl cli)
                , attribute "aria-label" <| Cli.label cli
                , style <|
                    Styles.topCliIcon
                        { hovered = hoveredTopCliIcon == Just cli
                        , cli = cli
                        }
                , id <| "top-cli-" ++ Cli.id cli
                , onMouseEnter <| TopCliHover <| Just cli
                , onMouseLeave <| TopCliHover Nothing
                ]
                []
    in
    if noPipelines then
        [ Html.div
            [ id "welcome-card"
            , style Styles.welcomeCard
            ]
            [ Html.div
                [ style Styles.welcomeCardTitle ]
                [ Html.text Text.welcome ]
            , Html.div
                [ style Styles.welcomeCardBody ]
              <|
                [ Html.div
                    [ style
                        [ ( "display", "flex" )
                        , ( "align-items", "center" )
                        ]
                    ]
                  <|
                    [ Html.div
                        [ style [ ( "margin-right", "10px" ) ] ]
                        [ Html.text Text.cliInstructions ]
                    ]
                        ++ List.map (cliIcon hoveredTopCliIcon) Cli.clis
                , Html.div
                    []
                    [ Html.text Text.setPipelineInstructions ]
                ]
                    ++ loginInstruction userState
            , Html.pre
                [ style Styles.asciiArt ]
                [ Html.text Text.asciiArt ]
            ]
        ]

    else
        []


loginInstruction : UserState.UserState -> List (Html Msg)
loginInstruction userState =
    case userState of
        UserState.UserStateLoggedIn _ ->
            []

        _ ->
            [ Html.div
                [ id "login-instruction"
                , style [ ( "line-height", "42px" ) ]
                ]
                [ Html.text "login "
                , Html.a
                    [ href "/login"
                    , style [ ( "text-decoration", "underline" ) ]
                    ]
                    [ Html.text "here" ]
                ]
            ]


noResultsView : String -> Html Msg
noResultsView query =
    let
        boldedQuery =
            Html.span [ class "monospace-bold" ] [ Html.text query ]
    in
    Html.div
        [ class <| .pageBodyClass Group.stickyHeaderConfig ]
        [ Html.div [ class "dashboard-content " ]
            [ Html.div
                [ class <| .sectionClass Group.stickyHeaderConfig ]
                [ Html.div [ class "no-results" ]
                    [ Html.text "No results for "
                    , boldedQuery
                    , Html.text " matched your search."
                    ]
                ]
            ]
        ]


helpView : { a | showHelp : Bool } -> Html Msg
helpView { showHelp } =
    Html.div
        [ classList
            [ ( "keyboard-help", True )
            , ( "hidden", not showHelp )
            ]
        ]
        [ Html.div
            [ class "help-title" ]
            [ Html.text "keyboard shortcuts" ]
        , Html.div
            [ class "help-line" ]
            [ Html.div
                [ class "keys" ]
                [ Html.span
                    [ class "key" ]
                    [ Html.text "/" ]
                ]
            , Html.text "search"
            ]
        , Html.div [ class "help-line" ]
            [ Html.div
                [ class "keys" ]
                [ Html.span
                    [ class "key" ]
                    [ Html.text "?" ]
                ]
            , Html.text "hide/show help"
            ]
        ]


turbulenceView : String -> Html Msg
turbulenceView path =
    Html.div
        [ class "error-message" ]
        [ Html.div [ class "message" ]
            [ Html.img [ src path, class "seatbelt" ] []
            , Html.p [] [ Html.text "experiencing turbulence" ]
            , Html.p [ class "explanation" ] []
            ]
        ]


pipelinesView :
    { a
        | groups : List Group.Group
        , substate : SubState.SubState
        , hoveredPipeline : Maybe Models.Pipeline
        , pipelineRunningKeyframes : String
        , query : String
        , userState : UserState.UserState
        , highDensity : Bool
        , dragChanged : Bool
    }
    -> List (Html Msg)
pipelinesView { groups, substate, hoveredPipeline, pipelineRunningKeyframes, query, userState, highDensity, dragChanged } =
    let
        filteredGroups =
            groups |> filter query |> List.sortWith Group.ordering

        groupsToDisplay =
            if List.all (String.startsWith "team:") (filterTerms query) then
                filteredGroups

            else
                filteredGroups |> List.filter (.pipelines >> List.isEmpty >> not)

        groupViews =
            if highDensity then
                groupsToDisplay
                    |> List.map (Group.hdView pipelineRunningKeyframes)

            else
                groupsToDisplay
                    |> List.map
                        (Group.view
                            { dragState = substate.dragState
                            , dragChanged = dragChanged
                            , now = substate.now
                            , hoveredPipeline = hoveredPipeline
                            , pipelineRunningKeyframes = pipelineRunningKeyframes
                            }
                        )
    in
    if List.isEmpty groupViews && (not <| String.isEmpty query) then
        [ noResultsView (toString query) ]

    else
        List.map Html.fromUnstyled groupViews


handleKeyPressed : Char -> Footer.Model r -> ( Footer.Model r, List Effect )
handleKeyPressed key model =
    case key of
        '/' ->
            ( model, [ FocusSearchInput ] )

        '?' ->
            ( Footer.toggleHelp model, [] )

        _ ->
            ( Footer.showFooter model, [] )


remoteUser : APIData.APIData -> Task.Task Http.Error ( APIData.APIData, Maybe Concourse.User )
remoteUser d =
    Concourse.User.fetchUser
        |> Task.map ((,) d << Just)
        |> Task.onError (always <| Task.succeed <| ( d, Nothing ))


filterTerms : String -> List String
filterTerms =
    replace All (regex "team:\\s*") (\_ -> "team:")
        >> replace All (regex "status:\\s*") (\_ -> "status:")
        >> String.words
        >> List.filter (not << String.isEmpty)


filter : String -> List Group.Group -> List Group.Group
filter =
    filterTerms >> flip (List.foldl filterGroupsByTerm)


filterPipelinesByTerm : String -> Group.Group -> Group.Group
filterPipelinesByTerm term ({ pipelines } as group) =
    let
        searchStatus =
            String.startsWith "status:" term

        statusSearchTerm =
            if searchStatus then
                String.dropLeft 7 term

            else
                term

        filterByStatus =
            fuzzySearch (.status >> PipelineStatus.show) statusSearchTerm pipelines
    in
    { group
        | pipelines =
            if searchStatus then
                filterByStatus

            else
                fuzzySearch .name term pipelines
    }


filterGroupsByTerm : String -> List Group.Group -> List Group.Group
filterGroupsByTerm term groups =
    let
        searchTeams =
            String.startsWith "team:" term

        teamSearchTerm =
            if searchTeams then
                String.dropLeft 5 term

            else
                term
    in
    if searchTeams then
        fuzzySearch .teamName teamSearchTerm groups

    else
        groups |> List.map (filterPipelinesByTerm term)


fuzzySearch : (a -> String) -> String -> List a -> List a
fuzzySearch map needle records =
    let
        negateSearch =
            String.startsWith "-" needle
    in
    if negateSearch then
        List.filter (not << Simple.Fuzzy.match needle << map) records

    else
        List.filter (Simple.Fuzzy.match needle << map) records
