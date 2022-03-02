(function(root){

	if(!root.OI) root.OI = {};

	root.OI.ready = function(f){
		if(/in/.test(document.readyState)) setTimeout('OI.ready('+f+')',9);
		else f();
	};

	// Make a copy of a structure
	function clone(a){
		return JSON.parse(JSON.stringify(a));
	}

	// Extend objects
	extendObject = (typeof Object.extend === 'undefined') ?
		function(destination, source) {
			for (var property in source) {
				if (source.hasOwnProperty(property)) destination[property] = source[property];
			}
			return destination;
		} : Object.extend;

	// Convert an object into an array
	function obj2arr(a){
		return Object.keys(a).map(function(i){a[i].id = i;return a[i];});
	}

	// Define a shortcut for checking variable types
	function is(a,b){ return (typeof a == b) ? true : false; }
	function indexOfMax(arr) {
		if(arr.length === 0) return -1;

		var max = arr[0];
		var maxIndex = 0;

		for(var i = 1; i < arr.length; i++){
			if(arr[i] > max){
				maxIndex = i;
				max = arr[i];
			}
		}
		return maxIndex;
	}

	function EValuator(opts){
		this.name = "EValuator";
		this.version = "0.1";
		if(!opts) opts = {};
		this.log = new Logger({'id':this.name,'logging':(location.search.indexOf("logging=true")>=0)});
		var el = opts.el||document.getElementById('map');
		if(!el){
			this.log.error('No element found to attach map to');
			return this;
		}

		this.el = el;
		
		this.lookup = {};
		this.LADs = [];
		this.LAD = "E08000035";
		
		// Get the LAD lookup
		fetch('data/LAD.tsv').then(response => {
			if(!response.ok) throw new Error('Network response was not OK');
			return response.text();
		}).then(data => {
			lines = data.split(/\n/);
			lines.shift();
			this.LADs = [];
			this.lookup.LAD = {};
			for(var i = 0; i < lines.length; i++){
				if(lines[i][1]){
					lines[i] = lines[i].split(/\t/);
					if(lines[i].length == 2){
						this.lookup.LAD[lines[i][0]] = {'name':lines[i][1]};
						this.LADs.push({'id':lines[i][0],'name':lines[i][1]});
					}
				}
			}
			this.init();
		}).catch(error => {
			console.error('There has been a problem with your fetch operation:', error);
		});

		return this;
	}

	EValuator.prototype.init = function(){

		var _obj = this;

		this.input = document.getElementById('LAD');

		// Build the barchart object attached to <input type="text" id="LAD">
		this.typeahead = TypeAhead.init(this.input,{
			'items': obj2arr(this.lookup.LAD),
			'process': function(d){ _obj.setLAD(d.id); },
			'rank': function(d,str){
				// Calculate a weighting
				var r = 0;
				// If the name starts with the string add 3
				if(d.name.toUpperCase().indexOf(str.toUpperCase())==0) r += 3;
				// If the name includes the string add 1
				if(d.name.toUpperCase().indexOf(str.toUpperCase())>0) r += 1;
				return r;
			},
			'render': function(d){ return d.name; },
			'this': this
		});

		return this;
	};
	
	EValuator.prototype.setLAD = function(id){
		if(id && this.lookup.LAD[id]){
			if(!this.lookup.LAD[id].MSOA){
				fetch('data/LAD/'+id+'/'+id+'-msoas.tsv').then(response => {
					if(!response.ok) throw new Error('Network response was not OK');
					return response.text();
				}).then(data => {
					lines = data.split(/\n/);
					this.lookup.LAD[id].MSOA = {};
					for(var i = 0; i < lines.length; i++){
						if(lines[i][1]){
							lines[i] = lines[i].split(/\t/);
							this.lookup.LAD[id].MSOA[lines[i][0]] = {'name':lines[i][1]};
						}
					}
					this.postLAD(id);
				}).catch(error => {
					console.error('There has been a problem with your fetch operation:', error);
				});
			}else{
				this.log.info('Already loaded MSOAs for '+id);
				this.postLAD(id);
			}
		}
	};
	
	EValuator.prototype.postLAD = function(id){
		console.log(id,this.lookup.LAD[id]);
		if(!this.lookup.LAD[id].MSOA){
			this.log.error('No MSOAs defined for '+this.lookup.LAD[id].name+' ('+id+')');
			return this;
		}
		this.LAD = id;
		this.input.setAttribute('placeholder',this.lookup.LAD[id].name);
		this.input.value = "";

		list = '';
		for(var m in this.lookup.LAD[this.LAD].MSOA){
			list += '<li>'+m+' - '+this.lookup.LAD[this.LAD].MSOA[m].name+'</li>';
		}
		el = document.getElementById('MSOAs');
		if(!el){
			el = document.createElement('ul');
			el.id = 'MSOAs';
			this.el.appendChild(el);
		}
		el.innerHTML = list;
		return this;
	};

	EValuator.prototype.loadGeoJSON = function(key){

		var color = this.maplayers[key].color||'black';
		var defaulttitle = this.maplayers[key].popuptitle||'?';
		
		fetch(this.maplayers[key].file).then(response => {
			if(!response.ok) throw new Error('Network response was not OK');
			return response.json();
		}).then(data => {

			for(var f = data.features.length-1 ; f >= 0; f--){
				// Remove points
				if(data.features[f].geometry.type=="Point"){
					data.features.splice(f,1);
				}
			}
			this.maplayers[key].data = data;

			if(this.mapper && this.mapper.map){
				
				var _obj = this;
				
				L.geoJSON(data, {
					style: function (feature) {
						return {color: color};
					}
				}).bindPopup(function (layer){
					g = layer.feature.geometry;
					p = layer.feature.properties;
					p.centroid = layer.getBounds().getCenter();
					popup = "";

					if(p){
						// If this feature has a default popup
						// Convert "other_tags" e.g "\"ele:msl\"=>\"105.8\",\"ele:source\"=>\"GPS\",\"material\"=>\"stone\""
						if(p.other_tags){
							tags = p.other_tags.split(/,/);
							for(var t = 0; t < tags.length; t++){
								tags[t] = tags[t].replace(/\"/g,"");
								bits = tags[t].split(/\=\>/);
								if(bits.length == 2){
									if(!p[bits[0]]) p[bits[0]] = bits[1];
								}
							}
						}


						var title = defaulttitle;
						if(p.title || p.name || p.Name) title = (p.title || p.name || p.Name);
						popup += '<h3>'+(title)+'</h3>';
						var added = 0;
						for(var f in p){
							if(f != "Name" && f!="name" && f!="title" && f!="other_tags" && (typeof p[f]==="number" || (typeof p[f]==="string" && p[f].length > 0))){
								popup += (added > 0 ? '<br />':'')+'<strong>'+f+':</strong> '+(typeof p[f]==="string" && p[f].indexOf("http")==0 ? '<a href="'+p[f]+'" target="_blank">'+p[f]+'</a>' : p[f])+'';
								added++;
							}
						}
						popup += '<p class="footer">Something not quite right? <a href="http://www.openstreetmap.org/edit?pk_campaign=open-innovations-edit'+(g.type == "Point" ? '&node={{osm_id}}':'')+(g.type == "Polygon" ? '&way={{osm_way_id}}' : '')+(g.type == "MultiPolygon" ? '&way={{osm_way_id}}' : '')+'#map=17/{{Latitude}}/{{Longitude}}" target="_osm">Help improve the data on OpenStreetMap</a>.</p>';

						// Loop over properties and replace anything
						for(var f in p){
							if(p[f]){
								while(popup.indexOf("{{"+f+"}}") >= 0){
									popup = popup.replace("{{"+f+"}}",p[f] || "?");
								}
							}
						}
						popup = popup.replace(/{{Latitude}}/g,(p.centroid ? p.centroid.lat : (g.coordinates ? g.coordinates[1] : '')));
						popup = popup.replace(/{{Longitude}}/g,(p.centroid ? p.centroid.lng : (g.coordinates ? g.coordinates[0] : '')));
						popup = popup.replace(/{{Zoom}}/g,_obj.mapper.map.getZoom()||18);
						popup = popup.replace(/{{type}}/g,g.type.toLowerCase());
					}

					return popup;
				}).addTo(this.mapper.map);
				this.updateCredits();
			}
			
		}).catch(error => {
			console.error('There has been a problem with your fetch operation:', error);
		});
		return this;
	}

	EValuator.prototype.loadCSVFile = function(key,cb){
		
		var _obj = this;
		
		fetch(this.maplayers[key].file).then(response => {
			if(!response.ok) throw new Error('Network response was not OK');
			return response.text();
		}).then(txt => {
			lines = txt.split(/\n/);
			rows = [];
			for(var r = 1; r < lines.length; r++){
				row = lines[r].split(/\,/);
				if(row[0]) rows.push(_obj.maplayers[key].parserow.call(this,row)||{'id':row[0]});
			}
			this.maplayers[key].data = rows;
			if(typeof cb==="function") cb.call(this,key);
			this.updateCredits();
		}).catch(error => {
			console.error('There has been a problem with your fetch operation:', error);
		});

		return this;
	}
	





	// Define a logging function
	function Logger(inp){
		if(!inp) inp = {};
		this.logging = (inp.logging||false);
		this.logtime = (inp.logtime||false);
		this.id = (inp.id||"JS");
		this.metrics = {};
		return this;
	}
	Logger.prototype.error = function(){ this.log('ERROR',arguments); };
	Logger.prototype.warning = function(){ this.log('WARNING',arguments); };
	Logger.prototype.info = function(){ this.log('INFO',arguments); };
	Logger.prototype.message = function(){ this.log('MESSAGE',arguments); }
	Logger.prototype.log = function(){
		if(this.logging || arguments[0]=="ERROR" || arguments[0]=="WARNING" || arguments[0]=="INFO"){
			var args,bold;
			args = Array.prototype.slice.call(arguments[1], 0);
			bold = 'font-weight:bold;';
			if(console && typeof console.log==="function"){
				if(arguments[0] == "ERROR") console.error('%c'+this.id+'%c:',bold,'',...args);
				else if(arguments[0] == "WARNING") console.warn('%c'+this.id+'%c:',bold,'',...args);
				else if(arguments[0] == "INFO") console.info('%c'+this.id+'%c:',bold,'',...args);
				else console.log('%c'+this.id+'%c:',bold,'',...args);
			}
		}
		return this;
	}
	Logger.prototype.time = function(key){
		if(!this.metrics[key]) this.metrics[key] = {'times':[],'start':''};
		if(!this.metrics[key].start) this.metrics[key].start = new Date();
		else{
			var t,w,v,tot,l,i,ts;
			t = ((new Date())-this.metrics[key].start);
			ts = this.metrics[key].times;
			// Define the weights for each time in the array
			w = [1,0.75,0.55,0.4,0.28,0.18,0.1,0.05,0.002];
			// Add this time to the start of the array
			ts.unshift(t);
			// Remove old times from the end
			if(ts.length > w.length-1) ts = ts.slice(0,w.length);
			// Work out the weighted average
			l = ts.length;
			this.metrics[key].av = 0;
			if(l > 0){
				for(i = 0, v = 0, tot = 0 ; i < l ; i++){
					v += ts[i]*w[i];
					tot += w[i];
				}
				this.metrics[key].av = v/tot;
			}
			this.metrics[key].times = ts.splice(0);
			if(this.logtime) this.info(key+' '+t+'ms ('+this.metrics[key].av.toFixed(1)+'ms av)');
			delete this.metrics[key].start;
		}
		return this;
	};
	
	root.OI.EValuator = function(opts){
		return new EValuator(opts);
	}
	root.Logger = Logger;

})(window || this);

/*!
	Typeahead search v0.1.7
*/
(function(root){

	function Builder(){
		this.version = "0.1.7";
		this.init = function(el,opt){ return new TA(el,opt); };
		return this;
	}
	/**
	 * @desc Create a new TypeAhead object
	 * @param {DOM|string} el - the DOM element
	 * @param {object} opt - configuration options
	 */
	function TA(el,opt){
		if(!opt) opt = {};
		if(typeof el==="string") el = document.querySelector(el);
		if(!el){
			console.warn('No valid element provided');
			return this;
		}
		var _obj = this;
		var evs = {};
		var items = opt.items||[];
		var results,form;
		var inline = (typeof opt.inline==="boolean" ? opt.inline : false);

		function search(s,e,t){

			var n,i,tmp,str,html,datum,ev;
			str = s.toUpperCase();

			// Rank the results
			tmp = [];
			if(str){
				for(i = 0 ; i < items.length; i++){
					datum = {'rank':0,'key':i,'value':items[i]};
					if(typeof opt.rank==="function") datum.rank = opt.rank(items[i],s);
					else{
						if(items[i].toUpperCase().indexOf(str) == 0) datum.rank += 3;
						if(items[i].toUpperCase().indexOf(str) > 0) datum.rank += 1;
					}
					tmp.push(datum);
				}
				tmp = sortBy(tmp,'rank');
			}

			// Add results to DOM
			if(!results){
				//el.parentElement.style.position = "relative";
				results = document.createElement('div');
				results.classList.add('typeahead-results');
				results.style.top = (el.offsetTop + el.offsetHeight)+'px';
				results.style.left = el.offsetLeft+'px';
				results.style.maxWidth = (el.parentElement.offsetWidth - el.offsetLeft - parseInt(window.getComputedStyle(el.parentElement, null).getPropertyValue('padding-right')))+'px';
				results.style.position = "absolute";
				//form.style.position = "relative";
				el.insertAdjacentElement('afterend',results);
			}

			html = "";
			if(tmp.length > 0){
				n = (typeof opt.max==="number") ? Math.min(tmp.length,opt.max) : tmp.length;
				html = "<ol>";
				for(i = 0; i < n; i++){
					if(tmp[i].rank > 0) html += '<li data-id="'+tmp[i].key+'" '+(i==0 ? ' class="selected"':'')+'><a tabindex="0" href="#" class="name">'+(typeof opt.render==="function" ? opt.render(items[tmp[i].key]) : items[tmp[i].key])+"</a></li>";
				}
				html += "</ol>";
			}
			results.innerHTML = html;
			if(inline) el.style.marginBottom = results.offsetHeight+'px';

			// Add click events
			var li = getLi();
			for(i = 0 ; i < li.length ; i++){
				li[i].addEventListener('click',function(ev){
					ev.preventDefault();
					ev.stopPropagation();
					selectLI(this.getAttribute('data-id'));
				});
			}
			
			if(evs[t]){
				e._typeahead = _obj;
				// Process each of the events attached to this event
				for(i = 0; i < evs[t].length; i++){
					ev = evs[t][i];
					e.data = ev.data||{};
					if(typeof ev.fn==="function") ev.fn.call(this,e);
				}
			}

			return this;
		}

		function getLi(){ return (results ? results.querySelectorAll('li') : []); }
		
		function selectLI(i){
			if(i){
				_obj.input = el;
				if(typeof opt.process==="function") opt.process.call(_obj,items[i]);
				else console.log(items[i]);
			}
			if(results) results.innerHTML = "";
			if(inline) el.style.marginBottom = "0px";
			return;
		}

		function submit(){
			var li = getLi();
			for(var i = 0; i < li.length; i++){
				if(li[i].classList.contains('selected')) return selectLI(li[i].getAttribute('data-id'));
			}
			return;
		}

		function highlight(keyCode){
			var li = getLi();
			var s = -1;
			var sel;
			for(var i = 0; i < li.length; i++){
				if(li[i].classList.contains('selected')) s = i;
			}
			sel = s;
			if(keyCode==40) s++;
			else s--;
			if(s < 0) s = li.length-1;
			if(s >= li.length) s = 0;
			if(sel >= 0) li[sel].classList.remove('selected');
			li[s].classList.add('selected');
		}
		this.update = function(){
			var ev = document.createEvent('HTMLEvents');
			ev.initEvent('keyup', false, true);
			el.dispatchEvent(ev);
			return this;
		}
		this.on = function(event,data,fn){
			if(!el){
				console.warn('Unable to attach event '+event);
				return this;
			}
			if(event=="change"){
				if(!evs[event]){
					evs[event] = [];
					el.addEventListener('keyup',function(e){
						e.preventDefault();
						e.stopPropagation();
						if(e.keyCode==40 || e.keyCode==38){
							highlight(e.keyCode);
						}else if(e.keyCode==13){
							submit();
						}else{
							// Match here
							search(this.value,e,event);
							if(typeof opt.endsearch==="function") opt.endsearch(this.value);
						}
					});
					el.addEventListener('blur',function(e){
						if(typeof opt.blur==="function") opt.blur();
					});
				}
				evs[event].push({'fn':fn,'data':data});
			}else if(event=="blur"){
				console.log('blur');
			}else console.warn('No event of type '+event);
			return this;
		};
		this.off = function(e,fn){
			// Remove any existing event from our list
			if(evs[e]){
				for(var i = 0; i < evs[e].length; i++){
					if(evs[e][i].fn==fn) evs[e].splice(i,1);
				}
			}
		};
		if(el.form){
			form = el.form;
			form.addEventListener('submit',function(e){
				e.preventDefault();
				e.stopPropagation();
				submit();
			},false);
		}
		if(el){
			el.setAttribute('autocomplete','off');
		}
		this.addItems = function(d){
			if(!items) items = [];
			items = items.concat(d);
		};
		this.clearItems = function(){ items = []; }
		this.on('change',{'test':'blah'},function(e){  });

		return this;
	}

	root.TypeAhead = new Builder();

	// Sort the data
	function sortBy(arr,i){
		return arr.sort(function (a, b) {
			return a[i] < b[i] ? 1 : -1;
		});
	}
	/* End Typeahead */

})(window || this);