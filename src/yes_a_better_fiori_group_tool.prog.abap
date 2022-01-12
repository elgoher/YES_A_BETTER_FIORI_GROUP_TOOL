*&---------------------------------------------------------------------*
*& Report  YES_A_BETTER_FIORI_GROUP_TOOL v0.1
*&
*&---------------------------------------------------------------------*
*&  Maintenance of Fiori groups in a less annoying way
*&---------------------------------------------------------------------*
*& Release 0.1 alpha
*& git repo:
*& author: Vinicius Barrionuevo
*&---------------------------------------------------------------------*
*&
*& TODOS:
*& - Handle Errors
*& - Assignment to a transport request
*& - Edit Group Title
*& - Switch contexts (the current version doesn't handle Client Specific)
*&---------------------------------------------------------------------*
report yes_a_better_fiori_group_tool.

tables sscrfields.

"!  Exception Handler for LCL_HTTP_CLIENT
class lxl_http_client definition inheriting from cx_static_check.

  public section.
    methods
      constructor
        importing
          i_message_text type string.

    data message_text type string read-only.

endclass.

class lxl_http_client implementation.

  method constructor.
    super->constructor( ).
    message_text = i_message_text.
  endmethod.

endclass.

"!  A minimalist HTTP Client
"!  Wraps (@link /iwfnd/cl_sutil_client_proxy).
class lcl_http_client definition.

  public section.

    "! Constructor
    "! Create an instance of the HTTP Client pointing to the base
    "! URI of the OData Service.
    "!
    "! @parameter i_service_uri | Base URI of OData Service
    "!                          | e.g. /sap/opu/odata/UI2/PAGE_BUILDER_CONF
    methods constructor
      importing
        i_service_uri type string.

    "! HTTP GET Method
    "!
    "! @parameter i_path        | Path to be read
    "!                          | e.g. /EntitySet('key')
    "! @parameter response_body | Returns response body in XSTRING
    "! @raising lxl_http_client | http client exception handler
    methods get
      importing
                i_path               type string
      returning value(response_body) type xstring
      raising   lxl_http_client.

    "! HTTP POST Method
    "!
    "! @parameter i_path           | Path to be read
    "!                             | e.g. /EntitySet
    "! @parameter i_request_body   | Request Body in XSTRING (JSON)
    "! @parameter response_body    | Returns response body in XSTRING
    "! @raising lxl_http_client    | http client exception handler
    methods post
      importing
                i_path               type string
                i_request_body       type xstring
      returning value(response_body) type xstring
      raising   lxl_http_client.

    "! HTTP DELETE Method
    "! @parameter i_path                | Path to be read
    "!                                  | e.g. /EntitySet('key')
    "! @raising lxl_http_client         | http client exception handler
    methods delete
      importing i_path type string
      raising   lxl_http_client.

    "! HTTP POST Method
    "!
    "! @parameter i_path                | Path to be read
    "!                                  | e.g. /EntitySet('key')
    "! @parameter i_request_body        | Request Body in XSTRING (JSON)
    "! @parameter response_body         | Returns response body in XSTRING
    "! @raising lxl_http_client         | http client exception handler
    methods put
      importing
                i_path               type string
                i_request_body       type xstring
      returning value(response_body) type xstring
      raising   lxl_http_client.

  private section.
    "! Base URI of the OData service
    data _service_uri type string.

    "! Calls (@link /iwfnd/cl_sutil_client_proxy.METH:web_request)
    methods _call_rest_client
      importing
        i_request_headers     type /iwfnd/sutil_property_t
        i_request_body        type xstring
      exporting
        e_request_body        type xstring
        e_status_code         type i
        e_status_text         type string
        e_content_type        type string
        e_response_headers    type /iwfnd/sutil_property_t
        e_response_body       type xstring
        e_add_request_headers type /iwfnd/sutil_property_t
        e_sap_client          type symandt
        e_local_client        type xsdboolean
        e_uri_prefix          type string
        e_sm59_http_dest      type rfcdest
        e_request_id          type char100
        e_error_type          type char1
        e_error_text          type string
        e_error_timestamp     type string
        e_duration            type i.

endclass.

class lcl_http_client implementation.

  method constructor.
    _service_uri = i_service_uri.
  endmethod.

  method get.

    data status_code type i.
    data error_text type string.
    data request_body type xstring.

    data(request_headers) = value /iwfnd/sutil_property_t(
      ( name = if_http_header_fields_sap=>request_method value = 'GET' )
      ( name = 'accept' value = 'application/json' )
      ( name = if_http_header_fields_sap=>request_uri value = _service_uri && i_path )
    ).

    _call_rest_client(
      exporting
       i_request_headers = request_headers
       i_request_body = request_body
      importing
        e_status_code = status_code
        e_error_text = error_text
        e_response_body = response_body
    ).

    if not status_code between 200 and 299.
      raise exception type lxl_http_client
        exporting
          i_message_text = |Code { status_code } - { error_text }|.
    endif.

  endmethod.

  method post.

    data(request_headers) = value /iwfnd/sutil_property_t(
      ( name = if_http_header_fields_sap=>request_method value = 'POST' )
      ( name = 'accept' value = 'application/json' )
      ( name = if_http_header_fields_sap=>request_uri value = _service_uri && i_path )
      ( name = 'Content-Type' value = 'application/json ; charset=utf-8' )
    ).

    data status_code type i.
    data error_text type string.

    _call_rest_client(
      exporting
       i_request_headers = request_headers
       i_request_body = i_request_body
      importing
        e_status_code = status_code
        e_error_text = error_text
        e_response_body = response_body
    ).

    if not status_code between 200 and 299.
      raise exception type lxl_http_client
        exporting
          i_message_text = |Code { status_code } - { error_text }|.
    endif.

  endmethod.

  method put.
  endmethod.


  method delete.

    data status_code type i.
    data error_text type string.
    data request_body type xstring.

    data(request_headers) = value /iwfnd/sutil_property_t(
      ( name = if_http_header_fields_sap=>request_method value = 'DELETE' )
      ( name = if_http_header_fields_sap=>request_uri value = _service_uri && i_path )
    ).

    _call_rest_client(
      exporting
       i_request_headers = request_headers
       i_request_body = request_body
      importing
        e_status_code = status_code
        e_error_text = error_text
    ).

    if not status_code between 200 and 299.
      raise exception type lxl_http_client
        exporting
          i_message_text = |Code { status_code } - { error_text }|.
    endif.

  endmethod.

  method _call_rest_client.

    data(http_client) = /iwfnd/cl_sutil_client_proxy=>get_instance( ).

    http_client->web_request(
      exporting
        it_request_header     = i_request_headers
        iv_request_body       = i_request_body
      importing
        ev_status_code        = e_status_code
        ev_status_text        = e_status_text
        ev_content_type       = e_content_type
        et_response_header    = e_response_headers
        ev_response_body      = e_response_body
        et_add_request_header = e_add_request_headers
        ev_sap_client         = e_sap_client
        ev_local_client       = e_local_client
        ev_uri_prefix         = e_uri_prefix
        ev_sm59_http_dest     = e_sm59_http_dest
        ev_request_id         = e_request_id
        ev_error_type         = e_error_type
        ev_error_text         = e_error_text
        ev_error_timestamp    = e_error_timestamp
        ev_duration           = e_duration
    ).

  endmethod.

endclass.


"!  Main class, where everything goes and
"! happens
class lcl_app definition create private.

  public section.

    types: begin of tile_alv,
             status      type icon-id,
             tile        type /ui2/if_fdm=>ts_tile,
             instance_id type string,
           end of tile_alv.

    types: begin of group_alv,
             group_id        type string,
             check_existence type abap_bool,
             group           type /ui2/fdm_page_gw_page_head,
           end of group_alv.

    class-methods
      get_instance returning value(result) type ref to lcl_app.

    "! Entry point of the report. Called in START-OF-SELECTION.
    "! Calls the main screen 9000.
    methods main.

    "! Handles PBO of screen 9000
    methods pbo.

    "! Handles PAI of screen 9000
    "!
    "! @parameter i_ucomm | User Command
    methods pai
      importing value(i_ucomm) type sy-ucomm.

    "! Handles EXIT commands of screen 9000
    "!
    "! @parameter i_ucomm | User Command
    methods exit
      importing value(i_ucomm) type sy-ucomm.

    "! Handles event ADDED_FUNCTION of CL_SALV_EVENTS (from CL_SALV_TABLE aka the ALV)
    "!
    "! @parameter e_salv_function | Function name
    methods on_user_command for event added_function of cl_salv_events
      importing e_salv_function.

    "! Handles event DOUBLE_CLICK of CL_SALV_EVENTS_TABLE (from CL_SALV_TABLE aka the ALV)
    "!
    "! @parameter row | The row that was double clicked
    methods on_double_click for event double_click of cl_salv_events_table
      importing row.

    "! Called when the user press the button Add Group in the toolbar of the ALV
    "!
    "! @parameter i_id              | Group ID
    "! @parameter i_title           | Group Title
    "! @parameter i_check_existence | Check if the group is already created and, if so,
    "!                              | load its assigned tiles
    methods add_group
      importing
        i_id              type string
        i_title           type string
        i_check_existence type sap_bool.

    "! Called when the user press the button 'Assign Tile to Group' in the toolbar of the ALV
    "!
    "! @parameter i_group_id        | Group ID
    "! @parameter i_catalog_id      | Catalog ID
    "! @parameter i_chip_id         | Chip ID (internal id used to manage tiles)
    "! @parameter result            | Instance ID of the created chip
    "! @raising lxl_http_client     | http client exception handler
    methods add_tile_to_group
      importing
                i_group_id    type string
                i_catalog_id  type string
                i_chip_id     type string
      returning value(result) type string
      raising   lxl_http_client.

    "! Called when the user press the button 'Unassign Tile from Group' in the toolbar of the ALV
    "!
    "! @parameter i_group_id        | Group ID
    "! @parameter i_instance_id     | Instance ID (internal id used to manage tiles)
    "! @raising lxl_http_client     | http client exception handler
    methods remove_tile_from_group
      importing
                i_group_id    type string
                i_instance_id type string
      raising   lxl_http_client.

    "! Called when the user press the button 'Load Catalog' in the toolbar of the ALV
    "! This method doesn't add a Catalog. It just loads the Tiles from the given Catalog
    "!
    "! @parameter i_key         | Catalog Key
    methods load_catalog
      importing
        i_key type /ui2/if_fdm=>ts_tile-key.

  private section.

    types:
      begin of chip,
        page_id     type string,
        instance_id type string,
        chip_id     type string,
      end of chip,
      chips type table of chip with key page_id instance_id,

      begin of chip_result,
        results type chips,
      end of chip_result,

      begin of chip_response,
        d type chip_result,
      end of chip_response,
      chips_response type table of chip_response.

    class-data _instance type ref to lcl_app.
    data _rest_client type ref to lcl_http_client.

    data:
      "! Container which everything goes in
      _main_container  type ref to cl_gui_docking_container,
      _split_container type ref to cl_gui_splitter_container.

    data:
      "! Groups Table (displayed in the ALV)
      _groups          type table of group_alv,
      "! Groups ALV
      _alv_group       type ref to cl_salv_table,
      "! Groups Container (for the ALV)
      _group_container type ref to cl_gui_container.

    data:
      "! Tiles Table (displayed in the ALV)
      _tiles          type table of tile_alv,
      "! Tiles ALV
      _alv_tile       type ref to cl_salv_table,
      "! Tiles Container (for the ALV)
      _tile_container type ref to cl_gui_container.

    "! Called when the user press the button Delete Group in the toolbar of the ALV
    methods _delete_group.

    "! Add tile as a chip to the selected Group
    methods _assign_tile_to_group.

    "! Remove the tile from the selected Group
    methods _unassign_tile_from_group.

    "! Get all tiles linked to the group
    methods _get_tiles_from_group
      importing i_group_id       type string
      exporting
                e_all_tiles      type /ui2/if_fdm=>tt_tile
                e_assigned_tiles type chips.

endclass.


class lcl_app implementation.

  method get_instance.
    if _instance is not bound.
      _instance = new #( ).
    endif.

    result = _instance.
  endmethod.

  method main.

    _rest_client = new #( '/sap/opu/odata/UI2/PAGE_BUILDER_CONF'  ).

    call screen 9000.

  endmethod.

  method pbo.

    if _alv_group is not bound.

      set pf-status 'SALV_STANDARD'.

      _main_container = new #(
        extension = 9999
        name = 'MAIN_CONTAINER'
      ).

      _split_container = new #(
        parent = _main_container
        columns = 1
        rows = 2
      ).

      _group_container = _split_container->get_container(
          row       = 1
          column    = 1
      ).

      cl_salv_table=>factory(
      exporting
        r_container = _group_container
      importing
        r_salv_table = _alv_group
      changing
        t_table = _groups
      ).

      _alv_group->get_functions( )->set_all( ).

      _alv_group->get_functions( )->add_function(
          name     = 'ADD_GROUP'
          icon     = conv #( icon_add_row )
          text     = 'Add Group'
          tooltip  = space
          position = 1
      ).

      _alv_group->get_functions( )->add_function(
          name     = 'DELETE_GROUP'
          icon     = conv #( icon_remove_row )
          text     = 'Delete group permanently'
          tooltip  = space
          position = 1
      ).

      data(event) = cast cl_salv_events_table( _alv_group->get_event( ) ).
      set handler on_user_command for event.
      set handler on_double_click for event.

      _alv_group->display( ).
    endif.

    if _alv_tile is not bound.

      _tile_container = _split_container->get_container(
        row       = 2
        column    = 1 ).

      cl_salv_table=>factory(
      exporting
        r_container = _tile_container
      importing
        r_salv_table = _alv_tile
      changing
        t_table = _tiles
      ).

      _alv_tile->get_functions( )->set_all( ).
      _alv_tile->get_functions( )->add_function(
          name     = 'LOAD_CATALOG'
          icon     = conv #( icon_add_row )
          text     = 'Load tiles from Catalog'
          tooltip  = space
          position = 1
      ).

      _alv_tile->get_functions( )->add_function(
          name     = 'ASSIGN'
          icon     = conv #( icon_assign )
          text     = 'Assign tile to group'
          tooltip  = space
          position = 2
      ).

      _alv_tile->get_functions( )->add_function(
          name     = 'UNASSIGN'
          icon     = conv #( icon_unassign )
          text     = 'Unassign tile from group'
          tooltip  = space
          position = 2
      ).

      event = cast cl_salv_events_table( _alv_tile->get_event( ) ).
      _alv_tile->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).
      set handler on_user_command for event.

      _alv_tile->display( ).

    endif.

  endmethod.


  method pai.

  endmethod.

  method exit.
    leave to screen 0.
  endmethod.

  method on_user_command.

    case e_salv_function.
      when 'ADD_GROUP'.
        call selection-screen 9001 starting at 10 10.
      when 'DELETE_GROUP'.
        _delete_group( ).
      when 'LOAD_CATALOG'.
        call selection-screen 9002 starting at 10 10.
      when 'ASSIGN'.
        _assign_tile_to_group( ).
      when 'UNASSIGN'.
        _unassign_tile_from_group( ).
    endcase.

  endmethod.

  method on_double_click.

    clear _tiles.

    data(selected_group) = _groups[ row ].
    if selected_group-check_existence = abap_true.
      _get_tiles_from_group(
        exporting i_group_id = selected_group-group_id
        importing
                  e_all_tiles = data(all_tiles)
                  e_assigned_tiles = data(assigned_tiles) ).

      loop at all_tiles assigning field-symbol(<tile>).

        append initial line to _tiles assigning field-symbol(<alv_tile>).
        <alv_tile>-tile = <tile>.

        loop at assigned_tiles assigning field-symbol(<assigned_tile>)
          where chip_id cs <tile>-key-id.
          <alv_tile>-status = icon_green_light.
          <alv_tile>-instance_id = <assigned_tile>-instance_id.
          exit.
        endloop.

      endloop.
    endif.

    _alv_tile->refresh( ).

  endmethod.

  method _get_tiles_from_group.

    data chip_response type chip_response.

    types:
      begin of catalog_data,
        catalog_id type string,
        data       type ref to /ui2/if_fdm_catalog_items,
      end of catalog_data.
    data catalog_datas type table of catalog_data.

    data(path) = |/Pages('{ i_group_id }')/PageChipInstances|.

    try.
        data(response_data) = _rest_client->get( i_path = path ).
      catch lxl_http_client.
        return.
    endtry.

    /ui2/cl_json=>deserialize(
      exporting
        jsonx            = response_data
        pretty_name      = abap_true
      changing
        data             = chip_response
    ).

    data dummy type string.
    data catalog_id type string.
    data instance_id type string.
    data tiles type /ui2/if_fdm=>tt_tile.

    data(catalog_api) = new /ui2/cl_fdm_catalog_api(
      iv_scope          = 'CONF'
      iv_use_cache      = abap_true ).

    e_assigned_tiles = chip_response-d-results.

    loop at e_assigned_tiles assigning field-symbol(<assigned_tile>).
      split <assigned_tile>-chip_id at ':' into dummy dummy catalog_id instance_id.

      if line_exists( catalog_datas[ catalog_id = catalog_id ] ).
        data(catalog_items) = catalog_datas[ catalog_id = catalog_id ]-data.
      else.
        catalog_items = catalog_api->/ui2/if_fdm_catalog_api~get_catalog_items(
            it_catalog_key            = value #( ( type = 'CAT' id = catalog_id ) )
        ).
        catalog_datas = value #( base catalog_datas
          ( catalog_id = catalog_id data = catalog_items )
        ).
      endif.

      catalog_items->get_data(
        importing
          et_tile         = tiles
      ).

      append lines of tiles to e_all_tiles.
    endloop.

  endmethod.

  method add_group.

    types:
      begin of group,
        id         type string,
        catalog_id type string,
        layout     type string,
        title      type string,
      end of group.

    types:
      begin of response_group,
        d type /ui2/fdm_page_gw_page_head,
      end of response_group.

    data request_data type xstring.
    data response_data type xstring.
    data response_group type response_group.

    if i_check_existence = abap_true.
      data(lv_path) = |/Pages('{ i_id }')|.

      try.
          response_data = _rest_client->get( i_path = lv_path ).
        catch lxl_http_client.
          " nothing to do
      endtry.
    endif.

    if response_data is initial.
      data(group) = value group(
                    id = i_id
                    catalog_id = '/UI2/FLPD_CATALOG'
                    layout = space
                    title = i_title ).


      data(json_request) = /ui2/cl_json=>serialize(
        exporting
          data             = group
          pretty_name      = abap_true
      ).

      call function 'SCMS_STRING_TO_XSTRING'
        exporting
          text     = json_request
          mimetype = 'text/plain; charset=utf-8'
        importing
          buffer   = request_data.

      try.
          response_data = _rest_client->post(
            exporting
              i_path         = '/Pages'
              i_request_body = request_data
          ).
        catch lxl_http_client into data(x_http_client).
          message x_http_client->message_text type 'S' display like 'E'.
          return.
      endtry.
    endif.

    /ui2/cl_json=>deserialize(
      exporting
        jsonx            = response_data
        pretty_name      = abap_true
      changing
        data             = response_group
    ).

    append initial line to _groups assigning field-symbol(<group_alv_group>).
    <group_alv_group>-group_id = i_id.
    <group_alv_group>-check_existence = i_check_existence.
    move-corresponding response_group-d to <group_alv_group>-group.

    _alv_group->refresh( ).


  endmethod.

  method _delete_group.

    data(selected_rows) = _alv_group->get_selections( )->get_selected_rows( ).
    if not line_exists( selected_rows[ 1 ] ).
      return.
    endif.

    data answer.
    call function 'POPUP_TO_CONFIRM_WITH_MESSAGE'
      exporting
        diagnosetext1 = 'This action will completely remove the selected group.'
        textline1     = 'Are you sure you want to proceed?'
        titel         = 'Warning'
      importing
        answer        = answer.
    if answer <> 'J'.
      return.
    endif.

    data(selected_group) = _groups[ selected_rows[ 1 ] ].
    data(path) = |/Pages('{ selected_group-group_id }')|.

    try.
        _rest_client->delete( path ).
        delete _groups index selected_rows[ 1 ].
        _alv_group->refresh( ).

        clear _tiles.
        _alv_tile->refresh( ).

      catch lxl_http_client into data(x_http_client).
        message x_http_client->message_text type 'S' display like 'E'.
    endtry.

  endmethod.

  method add_tile_to_group.

    types:
      begin of page_chip,
        page_id       type string,
        instance_id   type string,
        chip_id       type string,
        title         type string,
        configuration type string,
        layout_data   type string,
      end of page_chip.

    types:
      begin of response_page_chip,
        d type page_chip,
      end of response_page_chip.

    data response_page_chip type response_page_chip.
    data request_data type xstring.

    data(page_chip) = value page_chip(
                  page_id = i_group_id
                  chip_id = |X-SAP-UI2-PAGE:X-SAP-UI2-CATALOGPAGE:{ i_catalog_id }:{ i_chip_id }| ).

    data(json_request) = /ui2/cl_json=>serialize(
      exporting
        data             = page_chip
        pretty_name      = abap_true
    ).

    call function 'SCMS_STRING_TO_XSTRING'
      exporting
        text     = json_request
        mimetype = 'text/plain; charset=utf-8'
      importing
        buffer   = request_data.

    data(response_data) = _rest_client->post(
      exporting
        i_path         = '/PageChipInstances'
        i_request_body = request_data
    ).

    /ui2/cl_json=>deserialize(
      exporting
        jsonx            = response_data
        pretty_name      = abap_true
      changing
        data             = response_page_chip
    ).

    result = response_page_chip-d-instance_id.

  endmethod.

  method remove_tile_from_group.

    data(path) = |/PageChipInstances(pageId='{ i_group_id }',instanceId='{ i_instance_id }')|.
    _rest_client->delete(
      exporting
        i_path         = path
    ).

  endmethod.

  method load_catalog.

    data(catalog_api) = new /ui2/cl_fdm_catalog_api(
      iv_scope          = 'CONF'
      iv_use_cache      = abap_true ).

    data(catalog_items) = catalog_api->/ui2/if_fdm_catalog_api~get_catalog_items(
        it_catalog_key            = value #( ( type = 'CAT' id = i_key ) )
    ).

    data tiles type /ui2/if_fdm=>tt_tile.
    catalog_items->get_data(
      importing
        et_tile         = tiles
    ).

    _tiles = value #( base _tiles for tile in tiles
                      ( status = space tile = tile )
                    ).

    _alv_tile->refresh( ).

  endmethod.


  method _assign_tile_to_group.

    data(selected_rows) = _alv_group->get_selections( )->get_selected_rows( ).
    if not line_exists( selected_rows[ 1 ] ).
      return.
    endif.

    data(selected_group) = _groups[ selected_rows[ 1 ] ].

    selected_rows = _alv_tile->get_selections( )->get_selected_rows( ).
    loop at selected_rows assigning field-symbol(<selected_row>).

      data(selected_tile) = _tiles[ <selected_row> ].

      " ignore if tile is already assigned
      if selected_tile-status = icon_green_light.
        continue.
      endif.

      try.
          _tiles[ <selected_row> ]-instance_id = add_tile_to_group(
            i_group_id = selected_group-group_id
            i_catalog_id = conv #( selected_tile-tile-key-parent_key-id )
            i_chip_id = conv #( selected_tile-tile-key-id )
          ).
          _tiles[ <selected_row> ]-status = icon_green_light.
        catch lxl_http_client into data(x_http_client).
          _tiles[ <selected_row> ]-status = icon_red_light.
      endtry.

    endloop.

    _alv_tile->refresh( ).


  endmethod.

  method _unassign_tile_from_group.

    data(selected_rows) = _alv_group->get_selections( )->get_selected_rows( ).
    if not line_exists( selected_rows[ 1 ] ).
      return.
    endif.

    data(selected_group) = _groups[ selected_rows[ 1 ] ].

    selected_rows = _alv_tile->get_selections( )->get_selected_rows( ).
    loop at selected_rows assigning field-symbol(<selected_row>).

      data(selected_tile) = _tiles[ <selected_row> ].

      " ignore if tile is not assigned
      if selected_tile-status <> icon_green_light.
        continue.
      endif.

      try.
          remove_tile_from_group(
            i_group_id = selected_group-group_id
            i_instance_id = conv #( selected_tile-instance_id )
          ).
          clear _tiles[ <selected_row> ]-status.
        catch lxl_http_client into data(x_http_client).
          _tiles[ <selected_row> ]-status = icon_green_light.
      endtry.

    endloop.

    _alv_tile->refresh( ).

  endmethod.

endclass.




data app type ref to lcl_app.

initialization.
  app = lcl_app=>get_instance( ).

start-of-selection.
  app->main( ).



  selection-screen: begin of screen 9001.
    parameters: p_id type string lower case obligatory.
    parameters: p_title type string lower case obligatory.
    parameters: p_check as checkbox default abap_true.
  selection-screen: end of screen 9001.

  selection-screen: begin of screen 9002.
    parameters: p_key type /ui2/if_fdm=>ts_tile-key.
  selection-screen: end of screen 9002.

at selection-screen.
  if sy-dynnr = '9001' and sscrfields-ucomm = 'CRET'.
    app->add_group( i_id = p_id i_title = p_title i_check_existence = p_check ).
  endif.

  if sy-dynnr = '9002' and sscrfields-ucomm = 'CRET'.
    app->load_catalog( i_key = p_key ).
  endif.


module pbo output.
  app->pbo( ).
endmodule.

module pai input.
  app->pai( sy-ucomm ).
endmodule.

module exit input.
  app->exit( sy-ucomm ).
endmodule.
