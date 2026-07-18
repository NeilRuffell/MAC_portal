/**
 * EPG modile.
 */

(function(){

    function epg_constructor(){
        
        this.layer_name = 'epg';
        
        this.total_rows = 6;
        this.server_page_rows = 10;
        this.loaded_virtual_page = 0;
        this.load_request_id = 0;
        
        this.active_row_offset = 0;
        
        this.row_blocks  = ['number', 'name', 'epg_container'];
        
        this.load_params = {
            "type"   : "epg",
            "action" : "get_data_table"
        };
        
        this.ch_id = 0;
        
        this.parent = {};
        
        this.superclass = ListLayer.prototype;
        
        this.minutes_offset = 0;
        this.minutes_step = 90;
        
        this.cur_cell_col = 0;
        
        this.horiz_dir = 1;
        
        this.time_marks = [];
        
        this.marks_map = [];

        this.preview_scale = 0.60;

        this.live_line = {
            
            on : false,
            
            init : function(parent){
                _debug('epg.live_line.init');
                
                this.parent = parent;
                
                var container = create_block_element('live_line_container', this.parent.dom_obj);
                this.container = container;
                this.dom_obj = create_block_element('live_line', container);
                
                this.hide();
            },
            
            show : function(){
                _debug('epg.live_line.show');
                
                this.dom_obj.show();
                this.on = true;
            },
            
            hide : function(){
                _debug('epg.live_line.hide');
                
                this.dom_obj.hide();
                this.on = false;
            },
            
            check_time : function(){
                _debug('epg.live_line.check_time');
                
                if (!this.parent.result){
                    return;
                }
                
                var now = Math.ceil((new Date().getTime())/1000);
                var from = parseInt(this.parent.result.from_ts);
                var to   = parseInt(this.parent.result.to_ts);
                
                _debug('now', now);
                _debug('from', from);
                _debug('to', to);
                
                if (now > from && now < to){
                    this.show();
                    var minute = Math.floor((now - from)/60);
                    this.set_pos(minute);
                }else{
                    this.hide();
                }
            },
            
            set_pos : function(minute){
                _debug('epg.live_line.set_pos');
                
                /* 447/90 = 5px */
                var offset = (this.container.offsetWidth/90)*minute;
                
                _debug('offset', offset);
                
                this.dom_obj.moveX(offset);
            },
            
            start : function(){
                _debug('epg.live_line.start');
                
                this.check_time();
                
                var self = this;
                
                this.timer = window.setTimeout(function(){self.start()}, 10000);
            },
            
            stop : function(){
                _debug('epg.live_line.stop');
                
                window.clearTimeout(this.timer);
            }
        };
        
        this.show = function(do_not_load, player_overlay_mode){
            _debug('epg.show', do_not_load, player_overlay_mode);
            
            this.cur_page = 0;
            this.loaded_virtual_page = 0;
            
            this.parent.on = false;
            
            this.set_date_period();

            this.player_overlay_mode = player_overlay_mode;

            if (player_overlay_mode){
                this.dom_obj.style.background = 'none';
                this.dom_obj.setAttribute("overlay_mode", "1");
                this.color_buttons.buttons_bar.hide();
                this.header_path.hide();
            }else{
                this.dom_obj.style.background = '';
                this.dom_obj.setAttribute("overlay_mode", "0");
                this.color_buttons.buttons_bar.show();
                this.header_path.show();
            }
            
            this.superclass.show.call(this, false);

            this.show_tv_preview();
        };
        
        this.hide = function(do_not_reset){
            _debug('epg.hide');
            
            this.superclass.hide.call(this, do_not_reset);
            
            this.live_line.stop();

            this.program_info.innerHTML = '';
            this.on_date.innerHTML = '';

            if (this.player_overlay_mode){
                stb.set_cur_place(module.tv.layer_name);
                stb.set_cur_layer(module.tv);
            }

            this.return_to_main_menu = false;

            this.hide_tv_preview();
        };

        this.recalculate_preview_mode = function(){
            _debug('epg.recalculate_preview_mode');

            if (!module.tv || !module.tv.preview_pos || !module.tv.preview_box){
                return;
            }

            var epg_frame_style = window.getComputedStyle(this.tv_preview_box, null);
            var tv_frame_style = window.getComputedStyle(module.tv.preview_box, null);
            var frame_delta_x = parseFloat(epg_frame_style.left) - parseFloat(tv_frame_style.left);
            var frame_delta_y = parseFloat(epg_frame_style.top) - parseFloat(tv_frame_style.top);
            var video_mode = parseInt(stb.video_mode);
            var frame_scale = video_mode && stb.graphic_mode ? video_mode / stb.graphic_mode : 1;
            var frame_correction_x = video_mode == 1080 && stb.graphic_mode == 720 ? 4 : 0;

            this.preview_pos = {
                "mode"  : module.tv.preview_pos.mode,
                "xsize" : module.tv.preview_pos.xsize,
                "ysize" : module.tv.preview_pos.ysize,
                "x"     : Math.round(module.tv.preview_pos.x + frame_delta_x * frame_scale + frame_correction_x),
                "y"     : Math.round(module.tv.preview_pos.y + frame_delta_y * frame_scale)
            };

            var frame_width = (
                parseFloat(epg_frame_style.width) +
                parseFloat(epg_frame_style.paddingLeft) +
                parseFloat(epg_frame_style.paddingRight)
            ) * frame_scale;
            var frame_height = (
                parseFloat(epg_frame_style.height) +
                parseFloat(epg_frame_style.paddingTop) +
                parseFloat(epg_frame_style.paddingBottom)
            ) * frame_scale;
            var frame_anchor_x = this.preview_pos.x + (frame_width + this.preview_pos.xsize) / 2;
            var frame_anchor_y = this.preview_pos.y - (frame_height - this.preview_pos.ysize) / 2;

            this.preview_pos.x = Math.round(frame_anchor_x + (this.preview_pos.x - frame_anchor_x) * this.preview_scale);
            this.preview_pos.y = Math.round(frame_anchor_y + (this.preview_pos.y - frame_anchor_y) * this.preview_scale);
            this.preview_pos.xsize = Math.round(this.preview_pos.xsize * this.preview_scale);
            this.preview_pos.ysize = Math.round(this.preview_pos.ysize * this.preview_scale);

            if (stb.player.on && stb.player.is_tv && this.on){
                _debug('stb.SetViewport', this.preview_pos);
                stb.SetViewport(this.preview_pos.xsize, this.preview_pos.ysize, this.preview_pos.x, this.preview_pos.y)
            }
        };

        this.show_tv_preview = function(){
            _debug('epg.show_tv_preview');

            try{
                if (!stb.player.on || !stb.player.is_tv){
                    return;
                }

                if (this.tv_preview_box){
                    this.tv_preview_box.show();
                }

                stb.SetTopWin(1);
                this.recalculate_preview_mode();
            }catch(e){
                _debug(e);
            }
        };

        this.hide_tv_preview = function(){
            _debug('epg.hide_tv_preview');

            try{
                if (this.tv_preview_box){
                    this.tv_preview_box.hide();
                }

                stb.SetTopWin(0);
                stb.SetPIG(1, -1, -1, -1);
            }catch(e){
                _debug(e);
            }
        };
        
        this.init = function(){
            _debug('epg.init');
            
            this.superclass.init.call(this);
            
            this.program_info = create_block_element('program_info', this.dom_obj);
            
            this.on_date = create_block_element('on_date', this.dom_obj);
            
            var mark1 = create_block_element('time_mark mark-1', this.dom_obj);
            //mark1.style.left = '230px';
            this.time_marks.push(mark1);
            
            var mark2 = create_block_element('time_mark mark-2', this.dom_obj);
            //mark2.style.left = '380px';
            this.time_marks.push(mark2);
            
            var mark3 = create_block_element('time_mark mark-3', this.dom_obj);
            //mark3.style.left = '530px';
            this.time_marks.push(mark3);
            
            var mark4 = create_block_element('time_mark mark-4', this.dom_obj);
            //mark4.style.right = '38px';
            this.time_marks.push(mark4);

            this.tv_preview_box = create_block_element('tv_prev_window', this.dom_obj);
            this.tv_preview_box.style.webkitTransformOrigin = '100% 0';
            this.tv_preview_box.style.webkitTransform = 'scale(' + this.preview_scale + ')';
            this.tv_preview_box.style.transformOrigin = '100% 0';
            this.tv_preview_box.style.transform = 'scale(' + this.preview_scale + ')';
            this.tv_preview_box.hide();
        };
        
        this.reset = function(){
            _debug('epg.reset');
            
            this.minutes_offset = 0;
            
            this.superclass.reset.call(this);
        };
        
        this.bind = function(){
            
            this.shift_row.bind(key.UP, this, -1);
            this.shift_row.bind(key.DOWN, this, 1);
            
            this.shift_page.bind(key.PAGE_PREV, this, -1);
            this.shift_page.bind(key.PAGE_NEXT, this, 1);
            
            (function(){

                if (single_module.length){
                    return;
                }

                this.hide();
                if (!this.player_overlay_mode){
                    this.parent.hide();
                }
                main_menu.show();
            }).bind(key.MENU, this);
            
            (function(){

                stb.cur_place = 'epg';

                if (!this.active_row['epg_cell'][this.cur_cell_col]){
                    this.play_channel_from_row();
                    return;
                }

                if (this.active_row['epg_cell'][this.cur_cell_col].data.rec_id){
                    this.play(this.active_row['epg_cell'][this.cur_cell_col].data.rec_id);
                }else if (this.active_row['epg_cell'][this.cur_cell_col].data.mark_archive && this.tv_archive){
                    //_debug('this.active_row[epg_cell][this.cur_cell_col].data.mark_archive', this.active_row['epg_cell'][this.cur_cell_col].data.mark_archive);
                    if (!this.channel.wowza_dvr){

                    }
                    
                    this.tv_archive.play();
                }else{

                    var now = new Date().getTime() / 1000;

                    if (now > this.active_row['epg_cell'][this.cur_cell_col].data.start_timestamp && now < this.active_row['epg_cell'][this.cur_cell_col].data.stop_timestamp){
                        this.play_channel_from_row();
                    }
                }
            }).bind(key.OK, this);


            (function(){
                var return_to_main_menu = this.return_to_main_menu;

                if (return_to_main_menu){
                    this.hide();
                    this.parent.hide();
                    main_menu.show();
                    return;
                }

                if (!this.player_overlay_mode){
                    this.parent.load_params['from_ch_id'] = this.data_items[this.cur_row].ch_id;
                    this.parent._show.call(this.parent, this.parent.genre);
                }
                this.hide();
            }).bind(key.EXIT, this);
            
            this.horizontal_shift.bind(key.VOL_UP, this, 1);
            this.horizontal_shift.bind(key.VOL_DOWN, this, -1);
            
            this.horizontal_cell_shift.bind(key.RIGHT, this, 1);
            this.horizontal_cell_shift.bind(key.LEFT, this, -1);

            (function(){})
                .bind(key.CHANNEL_NEXT, this)
                .bind(key.CHANNEL_PREV, this)
                .bind(key.FFWD, this)
                .bind(key.REW, this)
                .bind(key.REC, this)
                .bind(key.PAUSE, this)
                .bind(key.BACK, this)
                .bind(key.APP, this)
                .bind(key.AUDIO, this)
                .bind(key.NUM0, this)
                .bind(key.NUM1, this)
                .bind(key.NUM2, this)
                .bind(key.NUM3, this)
                .bind(key.NUM4, this)
                .bind(key.NUM5, this)
                .bind(key.NUM6, this)
                .bind(key.NUM7, this)
                .bind(key.NUM8, this)
                .bind(key.NUM9, this)
                .bind(key.INFO, this);
        };

        this.play = function(rec_id){
            _debug('epg_simple.play', rec_id);

            var idx = stb.recordings.getIdxByVal('id', rec_id);

            if ( stb.recordings[idx] && !stb.recordings[idx].started){
                return;
            }

            this.active_row['epg_cell'][this.cur_cell_col].data.cmd  = 'auto /media/' + rec_id + '.mpg';
            this.active_row['epg_cell'][this.cur_cell_col].data.name = this.channel.name + ' — ' + this.active_row['epg_cell'][this.cur_cell_col].data.name;

            var self = this;

            stb.player.on_create_link = function(result){
                _debug('epg_simple.play.on_create_link', result);

                if (result.error == 'limit'){
                    stb.notice.show(word['player_limit_notice']);
                }else if(result.error == 'nothing_to_play'){
                    stb.notice.show(word['player_file_missing']);
                }else if(result.error == 'link_fault'){
                    stb.notice.show(word['player_server_error']);
                }else{

                    if (result.local == 1){
                        if (stb.IsFileExist && !stb.IsFileExist(result.cmd)){
                            stb.notice.show(get_word('rec_file_missing'));
                            return;
                        }
                    }

                    self.hide(true);

                    stb.player.prev_layer = self;
                    stb.player.need_show_info = 1;
                    stb.player.play_now(result.cmd);
                }
            };

            var channel = stb.player.channels[this.ch_id];

            _debug('this.ch_id', this.ch_id);
            _debug('channel', channel);

            if (channel){
                stb.player.cur_tv_item = channel;
            }

            stb.player.play(this.active_row['epg_cell'][this.cur_cell_col].data);
        };

        this.play_channel_from_row = function(){
            _debug('epg.play_channel_from_row');

            stb.cur_place = 'tv';

            var ch_idx = stb.player.channels.getIdxById(parseInt(this.data_items[this.cur_row].ch_id));

            stb.player.ch_idx = ch_idx || 0;
            stb.player.cur_media_item = stb.player.channels[stb.player.ch_idx];
            stb.player.cur_tv_item = stb.player.channels[stb.player.ch_idx];
            stb.player.last_not_locked_tv_item = stb.player.channels[stb.player.ch_idx];

            this.hide(true);

            stb.player.prev_layer = this;
            stb.player.need_show_info = 0;
            stb.player.play(stb.player.cur_media_item);
        };
        
        this.set_date_period = function(){
            _debug('epg.set_date_period');
            
            var date = new Date();

            var year    = date.getFullYear();
            var month   = date.getMonth();
            var day     = date.getDate();
            var hours   = date.getHours();
            var minutes = date.getMinutes();
            
            if (minutes<30){
                minutes = 0;
            }else{
                minutes = 30;
            }
            
            minutes += this.minutes_offset;
            
            _debug('date', year, month, day, hours, minutes);
            
            var date_from = new Date(year, month, day, hours, minutes);
            var from = date_from.getFullYear()+'-'+this.format_date(date_from.getMonth()+1)+'-'+this.format_date(date_from.getDate())+' '+this.format_date(date_from.getHours())+':'+this.format_date(date_from.getMinutes())+':00';
            _debug('from', from);
            this.load_params['from_ts'] = date_from.getTime();
            this.load_params['from'] = from;

            var date_to = new Date(year, month, day, hours, minutes+90);
            var to = date_to.getFullYear()+'-'+this.format_date(date_to.getMonth()+1)+'-'+this.format_date(date_to.getDate())+' '+this.format_date(date_to.getHours())+':'+this.format_date(date_to.getMinutes())+':00';
            _debug('to', to);
            this.load_params['to_ts'] = date_to.getTime();
            this.load_params['to'] = to;

        };
        
        this.load_data = function(){
            _debug('epg.load_data');
            
            _debug('this.ch_id', this.ch_id);

            this.load_params['fav'] = stb.user.fav_itv_on;
            
            this.set_passive_cell();
            this.set_passive_row();
            
            this.marks_map = [];
            
            this.live_line.stop();
            
            this.load_params['ch_id'] = this.ch_id;

            this.set_total_items(-1);

            this.loading = true;

            this.loader && this.loader.abort && this.loader.abort();

            this.break_filling_list = true;

            var request_id = ++this.load_request_id;

            if (this.cur_page == 0){
                this.load_initial_virtual_page(request_id);
            }else{
                this.load_virtual_page(this.cur_page, null, request_id);
            }
        };

        this.get_page_load_params = function(page){
            var params = this.load_params.clone();
            params['p'] = page;
            return params;
        };

        this.load_initial_virtual_page = function(request_id){
            _debug('epg.load_initial_virtual_page');

            this.loader = stb.load(
                this.get_page_load_params(0),
                function(result){
                    if (request_id != this.load_request_id){
                        return;
                    }

                    var server_page_rows = parseInt(result.max_page_items, 10);
                    if (server_page_rows > 0){
                        this.server_page_rows = server_page_rows;
                    }

                    var global_row = 0;
                    if (result.cur_page > 0 && result.selected_item > 0){
                        global_row = (result.cur_page - 1) * this.server_page_rows + result.selected_item - 1;
                    }

                    var virtual_page = Math.floor(global_row / this.total_rows) + 1;
                    var selected_row = global_row % this.total_rows;

                    this.load_virtual_page(virtual_page, selected_row, request_id);
                },
                this
            );
        };

        this.load_virtual_page = function(page, selected_row, request_id){
            _debug('epg.load_virtual_page', page, selected_row);

            // The stock API pages in tens, so a six-row page may span two responses.
            var first_global_row = (page - 1) * this.total_rows;
            var server_page = Math.floor(first_global_row / this.server_page_rows) + 1;
            var server_offset = first_global_row % this.server_page_rows;

            this.loader = stb.load(
                this.get_page_load_params(server_page),
                function(result){
                    if (request_id != this.load_request_id){
                        return;
                    }

                    var data = result.data.slice(server_offset, server_offset + this.total_rows);
                    var rows_needed = this.total_rows - data.length;

                    if (rows_needed > 0 && first_global_row + data.length < result.total_items){
                        this.load_virtual_page_tail(result, data, server_page + 1, rows_needed, page, selected_row, request_id);
                    }else{
                        this.finish_virtual_page(result, data, page, selected_row, request_id);
                    }
                },
                this
            );
        };

        this.load_virtual_page_tail = function(result, data, server_page, rows_needed, page, selected_row, request_id){
            _debug('epg.load_virtual_page_tail', server_page, rows_needed);

            this.loader = stb.load(
                this.get_page_load_params(server_page),
                function(tail_result){
                    if (request_id != this.load_request_id){
                        return;
                    }

                    data = data.concat(tail_result.data.slice(0, rows_needed));
                    this.finish_virtual_page(result, data, page, selected_row, request_id);
                },
                this
            );
        };

        this.finish_virtual_page = function(result, data, page, selected_row, request_id){
            _debug('epg.finish_virtual_page', page, selected_row);

            if (request_id != this.load_request_id){
                return;
            }

            if (selected_row === null){
                if (page == this.loaded_virtual_page){
                    selected_row = this.cur_row;
                }else if (this.page_dir > 0){
                    selected_row = 0;
                }else{
                    selected_row = data.length - 1;
                }
            }

            selected_row = Math.max(0, Math.min(selected_row, data.length - 1));

            result.data = data;
            result.max_page_items = this.total_rows;
            result.cur_page = page;
            result.selected_item = data.length ? selected_row + 1 : 0;

            this.break_filling_list = false;
            this.result = result;
            this.total_pages = Math.ceil(result.total_items / this.total_rows);
            this.cur_page = page;
            this.cur_row = selected_row;
            this.loaded_virtual_page = page;

            this.set_total_items(result.total_items);
            this.fill_list(data);
        };

        this.fill_dvb_epg = function(data){
            _debug('epg.fill_dvb_epg');

            if (!module.dvb){
                return data;
            }

            for (var i=0; i<data.length; i++){
                if(data[i].ch_type == 'dvb'){
                    data[i].epg = module.dvb.get_epg_for_table(data[i].dvb_id, this.load_params['from_ts']/1000, this.load_params['to_ts']/1000);
                }
            }

            return data;
        };
        
        this.fill_list = function(data){
            _debug('epg.fill_list');

            data = this.fill_dvb_epg(data);
            
            this.superclass.fill_list.call(this, data);
            
            for (var i=0; i<data.length; i++){
                
                this.post_handling_epg_block(this.map[i], data[i].epg);
            }
            
            this.set_marks(this.result.time_marks);
            
            this.set_active_cell();
            
            this.live_line.start();
        };
        
        this.set_marks = function(marks){
            _debug('epg.set_marks', marks);
            
            for (var i=0; i<this.time_marks.length; i++){
                
                if (i < (this.time_marks.length - 1)){
                    this.time_marks[i].innerHTML = '|' + marks[i];
                }else{
                    this.time_marks[i].innerHTML = marks[i] + '|';
                }
            }
        };
        
        this.set_active_row = function(num){
            _debug('epg.set_active_row', num);
            
            this.set_passive_cell();
            
            this.set_passive_row();

            this.active_row = this.map[num];
            
            this.active_row.row.setAttribute('active', 'active');
            
            this.ch_id   = this.data_items[num].ch_id;
            this.channel = stb.player.channels[stb.player.channels.getIdxById(this.ch_id)];

            if (!this.channel){
                this.channel = module.tv.data_items[module.tv.data_items.getIdxById(this.ch_id)];
            }

            this.set_active_cell();
        };
        
        this.set_passive_row = function(){
            _debug('epg.set_passive_row', this.prev_row);
            
            this.map[this.prev_row].row.setAttribute('active', '');
            this.map[this.cur_row].row.setAttribute('active', '');
        };
        
        this.post_handling_epg_block = function(item, epg, is_active_row){
            _debug('epg.post_handling_block', is_active_row);
            
            //var total_container_width = 449;
            var total_container_width = this.map[this.cur_row].epg_container_block.offsetWidth;

            this.clear_program_container(item, 'epg_container_block');
                
            var epg_length = epg.length;
            
            _debug('epg_length', epg_length);
            
            /* 2px - on each separator */
            var separator_width = (epg_length-1)*2;
            
            var container_width = total_container_width - separator_width;
            
            var total_program_width = 0;
            
            if (is_active_row){
                this.active_row['epg_cell'] = [];
            }
            
            item['epg_cell'] = [];
            
            for (var j=0; j<epg_length; j++){
                
                var block = create_block_element('program', item['epg_container_block']);
                //this.epg_container_block = block;
                
                var program_width = Math.floor(container_width * epg[j]['display_duration'] / 5400); // 90m = 5400s
                _debug('program_width', program_width);
                
                total_program_width += program_width;
                
                if (j == (epg_length-1)){
                    program_width += container_width - total_program_width;
                }
                
                block.style.width = program_width+'px';
                
                /*if (is_active_row){
                    this.active_row['epg_cell'].push({"cell" : block, "data" : epg[j]});
                }*/
                
                item['epg_cell'].push({"cell" : block, "data" : epg[j]});
                
                if (epg[j]['larr']){
                    create_block_element('larr', block);
                }
                
                if (epg[j]['rarr']){
                    create_block_element('rarr', block);
                }
                
                var txt_block = create_block_element('program_txt', block);
                
                txt_block.innerHTML = epg[j]['name'];
                
                var marks = create_block_element('marks', block);
                
                var mark_memo = create_block_element('mark_memo', marks);
                
                if (epg[j]['mark_memo']){
                    mark_memo.show();
                }else{
                    mark_memo.hide();
                }
                
                var mark_rec = create_block_element('mark_rec', marks);
                
                if (epg[j]['mark_rec']){
                    mark_rec.show();
                }else{
                    mark_rec.hide();
                }

                var mark_archive = create_block_element('mark_archive', marks);

                if (epg[j]['mark_archive'] && module.tv_archive){
                    mark_archive.show();
                }else{
                    mark_archive.hide();
                }
                
                if (!is_active_row){
                    this.marks_map.push({"program_id" : epg[j]['id'], "mark_memo" : mark_memo, "mark_rec" : mark_rec, "mark_archive" : mark_archive});
                }
                
                if (j < epg_length-1){
                    create_block_element('program_separator', item['epg_container_block']);
                }
            }
        };
        
        this.clear_program_container = function(item, block_name){
            _debug('epg.clear_program_container', item, block_name);
            
            var container = item[block_name];
            
            var length = container.childNodes.length;
            
            for (var i=0; i<length; i++){
                container.removeChild(container.lastChild);
            }
        };
        
        this.format_date = function(param){
            if (param<10){
                return '0'+param
            }
            return param
        };
        
        this.horizontal_shift = function(dir){
            _debug('epg.horizontal_shift', dir);
            
            this.horiz_dir = dir;
            
            if (dir>0){
                this.minutes_offset += this.minutes_step;
            }else{
                this.minutes_offset -= this.minutes_step;
            }
            
            _debug('this.minutes_offset', this.minutes_offset);
            
            this.set_date_period();
            this.load_data();
        };
        
        this.horizontal_cell_shift = function(dir){
            _debug('epg.horizontal_cell_shift', dir);
            
            this.set_passive_cell();
            
            if (dir > 0){
                
                if (this.cur_cell_col < this.data_items[this.cur_row].epg.length - 1){
                    this.cur_cell_col++;
                    this.set_active_cell();
                }else{
                    this.horizontal_shift(1);
                }
                
            }else{
                if (this.cur_cell_col > 0){
                    this.cur_cell_col--;
                    this.set_active_cell();
                }else{
                    this.horizontal_shift(-1);
                }
            }
        };
        
        this.set_active_cell = function(){
            _debug('epg.set_active_cell', this.cur_cell_col);
            
            if (this.horiz_dir > 0){
                this.cur_cell_col = 0;
            //}else if (this.horiz_dir < 0){
            }else if (this.horiz_dir < 0){
                this.cur_cell_col = this.active_row['epg_cell'].length - 1;
            }else{
                
                if (this.active_row['epg_cell'] && empty(this.active_row['epg_cell'][this.cur_cell_col])){
                    this.cur_cell_col = this.active_row['epg_cell'].length - 1;
                }
            }
            
            _debug('this.horiz_dir', this.horiz_dir);
            _debug('this.cur_cell_col', this.cur_cell_col);

            var now = (new Date().getTime()) / 1000;

            _debug('now', now);
            
            if (!empty(this.active_row['epg_cell']) && !empty(this.active_row['epg_cell'][this.cur_cell_col])){

                _debug('this.active_row[epg_cell][this.cur_cell_col]', this.active_row['epg_cell'][this.cur_cell_col]);

                this.active_row['epg_cell'][this.cur_cell_col].cell.setAttribute('rel', 'active');

                this.color_buttons.get('yellow').disable();

                if (now > this.active_row['epg_cell'][this.cur_cell_col].data.start_timestamp){
                    this.color_buttons.get('red')  .disable();
                    this.color_buttons.get('green').disable();

                    if (now >= this.active_row['epg_cell'][this.cur_cell_col].data.start_timestamp && module.downloads && this.active_row['epg_cell'][this.cur_cell_col].data.mark_archive && this.tv_archive && !parseInt(this.channel.wowza_dvr, 10)){
                        this.color_buttons.get('yellow').enable();
                    }

                }else{
                    if (module.remote_pvr && this.channel.allow_pvr || module.pvr_local && this.channel.allow_local_pvr){
                        this.color_buttons.get('red').enable();
                    }else{
                        this.color_buttons.get('red').disable();
                    }
                    this.color_buttons.get('green').enable();
                }
            }else{
                this.color_buttons.get('red')  .disable();
                this.color_buttons.get('green').disable();
            }
            
            this.fill_program_info();
            
            this.horiz_dir = 0;
        };
        
        this.set_passive_cell = function(){
            _debug('epg.set_passive_cell', this.cur_cell_col);
            
            if (!empty(this.active_row['epg_cell']) && !empty(this.active_row['epg_cell'][this.cur_cell_col])){
            
                this.active_row['epg_cell'][this.cur_cell_col].cell.setAttribute('rel', '');
            }
        };
        
        this.init_page_bar = function(){};
        
        this.set_total_items = function(count){
            _debug('epg.set_total_items', count);
        };
        
        this.fill_program_info = function(){
            _debug('epg.fill_program_info');
            
            if (!empty(this.active_row['epg_cell']) && !empty(this.active_row['epg_cell'][this.cur_cell_col])){
                
                this.program_info.innerHTML = '<span class="time">' + this.active_row['epg_cell'][this.cur_cell_col].data['t_time']
                    + ' - ' + this.active_row['epg_cell'][this.cur_cell_col].data['t_time_to'] +'</span> - '
                    + this.active_row['epg_cell'][this.cur_cell_col].data['name']
                    + (this.active_row['epg_cell'][this.cur_cell_col].data['descr'] ? ' (' + this.active_row['epg_cell'][this.cur_cell_col].data['descr'] + ')' : '');
                
                _debug('on_date', this.active_row['epg_cell'][this.cur_cell_col].data['on_date']);
                this.on_date.innerHTML = this.active_row['epg_cell'][this.cur_cell_col].data['on_date'];
            }else{
                this.program_info.innerHTML = '';
                this.on_date.innerHTML = '';
            }
        };

        this.add_download = function(url, to_filename){
            _debug('epg_simple.add_download', url, to_filename);

            if (module.downloads){
                _debug('downloads');
                module.downloads.dialog.show({"secure_url" : true, "parent" : this, "url" : url, "name" : to_filename});
            }
        }
    }
    
    epg_constructor.prototype = new ListLayer();
    
    var epg = new epg_constructor();
    
    epg.parent = module.tv;
    
    if (module.epg_reminder){
        epg.reminder = function(){};
        
        epg.reminder.prototype = module.epg_reminder;
        epg.reminder = new epg.reminder;
        epg.reminder.parent = epg;
        
        epg.reminder.get_ch_id = function(){
            _debug('epg.reminder.get_ch_id');
            
            return this.parent.data_items[this.parent.cur_row].ch_id;
        };
        
        epg.reminder.get_item = function(){
            _debug('epg.reminder.get_item');
            
            return this.parent.data_items[this.parent.cur_row].epg[this.parent.cur_cell_col];
        };
    }

    if (module.epg_recorder){
        epg.recorder = function(){};

        epg.recorder.prototype = module.epg_recorder;
        epg.recorder = new epg.recorder;
        epg.recorder.parent = epg;
    }

    if (module.tv_archive){
        epg.tv_archive = function(){};

        epg.tv_archive.prototype = module.tv_archive;
        epg.tv_archive = new epg.tv_archive;
        epg.tv_archive.parent = epg;

        epg.tv_archive.get_item = function(){
            _debug('epg.tv_archive.get_item');

            return this.parent.data_items[this.parent.cur_row].epg[this.parent.cur_cell_col];
        };

        epg.tv_archive.get_channel_name = function(){
            _debug('epg.tv_archive.get_channel_name');

            return this.parent.channel.name;
        };
    }
    
    epg.bind();
    epg.init();
    epg.live_line.init(epg);
    
    epg.init_header_path(word['epg_title']);
    
    epg.init_color_buttons([
        {"label" : word['epg_record'], "cmd" : (function(){if (epg.recorder){return function(){epg.recorder.add_del()}}else{return ''}})()},
        {"label" : word['epg_remind'], "cmd" : (function(){if (epg.reminder){return function(){epg.reminder.add_del()}}else{return ''}})()},
        {"label" : word['downloads_download'], "cmd" : stb.all_modules.indexOf('downloads') >=0 ? function(){epg.tv_archive.play.call(epg.tv_archive, true, function(url, to_file){epg.add_download.call(epg, url, to_file)})} : ''},
        {"label" : word['empty'], "cmd" : ''}
    ]);
    
    epg.hide();
    
    module.epg = epg;
    
})();

loader.next();
