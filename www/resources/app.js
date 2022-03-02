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
		this.scores = {};
		this.LAD = "E08000035";
		
		
		
		// Get the LAD lookup
		fetch('data/LAD.tsv').then(response => {
			if(!response.ok) throw new Error('Network response was not OK');
			return response.text();
		}).then(data => {
			lines = data.split(/\n/);
			lines.shift();
			this.lookup.LAD = {};
			for(var i = 0; i < lines.length; i++){
				if(lines[i][1]){
					lines[i] = lines[i].split(/\t/);
					if(lines[i].length == 2){
						this.lookup.LAD[lines[i][0]] = {'name':lines[i][1]};
					}
				}
			}
			
				
			fetch("data/layers.json").then(response => {
				if(!response.ok) throw new Error('Network response was not OK');
				return response.json();
			}).then(data => {
				this.layers = data;
				this.init();
			}).catch(error => {
				console.error('There has been a problem with your fetch operation:', error);
			});
			
			
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
		
		// Map
		baseMaps = {
			'Greyscale': L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
				attribution: 'Tiles: &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
				subdomains: 'abcd',
				maxZoom: 19
			})
		};

		var lat = 53.79659;
		var lon = -1.53385;
		var d = 4;
		var bbox = [[lat-d, lon-d],[lat+d, lon+d]];

		this.map = L.map(this.el,{'layers':[baseMaps["Greyscale"]],'scrollWheelZoom':true,'editable': true,'zoomControl': true}).fitBounds(bbox);

		return this;
	};
	
	EValuator.prototype.setLAD = function(id){
		if(id && this.lookup.LAD[id]){
			if(!this.lookup.LAD[id].MSOA){

/*
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
*/
				fetch('data/LAD/'+id+'/'+id+'.csv').then(response => {
					if(!response.ok) throw new Error('Network response was not OK');
					return response.text();
				}).then(data => {
					lines = data.split(/\n/);
					this.lookup.LAD[id].MSOA = {};
					header = lines[0].split(/,/);
					for(var i = 1; i < lines.length; i++){
						if(lines[i][1]){
							lines[i] = lines[i].split(/\,/);
							this.lookup.LAD[id].MSOA[lines[i][0]] = {'name':lines[i][1].replace(/(^\"|\"$)/g,"")};
							for(h = 2; h < header.length; h++){
								if(!this.scores[lines[i][0]]) this.scores[lines[i][0]] = {};
								this.scores[lines[i][0]][header[h]] = parseFloat(lines[i][h]);
							}
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

		// Update the input field
		this.input.setAttribute('placeholder',this.lookup.LAD[id].name);
		this.input.value = "";



		// Find the min/max for each layers
		for(var l = 0; l < this.layers.length; l++){
			min = 1e100;
			max = -1e100;
			// Loop over the MSOAs in this LAD
			for(msoa in this.lookup.LAD[id].MSOA){
				if(typeof this.scores[msoa][this.layers[l].id]==="number"){
					min = Math.min(this.scores[msoa][this.layers[l].id],min);
					max = Math.max(this.scores[msoa][this.layers[l].id],max);
				}else{
					this.log.warning('No score for '+this.layers[l].id+' for '+msoa);
				}
			}
			this.layers[l].min = min;
			this.layers[l].max = max;
			this.layers[l].range = max - min;
			// Avoid zero ranges causing divide-by-zero errors
			if(this.layers[l].range == 0) this.layers[l].range = 1;
			this.layers[l].weight = 1;
		}
		
		var weight = 0;
		for(var l = 0; l < this.layers.length; l++) weight += this.layers[l].weight;

		for(msoa in this.lookup.LAD[id].MSOA){
			this.scores[msoa].total = 0;
			for(var l = 0; l < this.layers.length; l++){
				if(this.layers[l].invert){
					this.scores[msoa].total += 1 - (this.layers[l].weight)*(this.scores[msoa][this.layers[l].id] - this.layers[l].min)/this.layers[l].range;
				}else{
					this.scores[msoa].total += (this.layers[l].weight)*(this.scores[msoa][this.layers[l].id] - this.layers[l].min)/this.layers[l].range;
				}
			}
			this.scores[msoa].total = this.scores[msoa].total/weight;
		}


		totals = [];
		for(var msoa in this.lookup.LAD[this.LAD].MSOA){
			totals.push([msoa,this.scores[msoa].total]);
		}
		totals.sort(function(a, b) {
			return b[1] - a[1];
		});

		list = '<tr><th>Rank</th><th>MSOA</th><th>Name</th>';
		for(var l = 0; l < this.layers.length; l++){
			list += '<th>'+this.layers[l].title+'</th>';
		}
		list += '<th>Total</th>';
		list += '</tr>';
		for(var t = 0; t < totals.length; t++){
			msoa = totals[t][0];
			list += '<tr><td class="num">'+(t+1)+'</td><td>'+msoa+'</td>';
			list += '<td>'+this.lookup.LAD[this.LAD].MSOA[msoa].name+'</td>';
			for(var l = 0; l < this.layers.length; l++){
				list += '<td class="num">'+this.scores[msoa][this.layers[l].id]+'</td>';
			}
			list += '<td class="num">'+this.scores[msoa].total.toFixed(2)+'</td>';
			list += '</tr>';
		}
		el = document.getElementById('MSOAs');
		if(!el){
			el = document.createElement('ul');
			el.id = 'MSOAs';
			this.el.appendChild(el);
		}
		el.innerHTML = '<table>'+list+'</table>';



		if(!this.lookup.LAD[id].geoJSON){
			fetch('data/LAD/'+id+'/'+id+'.geojson').then(response => {
				if(!response.ok) throw new Error('Network response was not OK');
				return response.json();
			}).then(data => {
				this.lookup.LAD[id].geoJSON = data;
				this.updateMap(id);
			}).catch(error => {
				console.error('There has been a problem with your fetch operation:', error);
			});
		}else{
			this.updateMap(id);
		}


		return this;
	};

	EValuator.prototype.updateMap = function(id){
		
		if(this.lookup.LAD[id].geoJSON){
			if(this.LADlayer) this.map.removeLayer(this.LADlayer);

			var weight = 0;
			for(var l = 0; l < this.layers.length; l++) weight += this.layers[l].weight;

			var _obj = this;
			this.LADlayer = L.geoJSON(this.lookup.LAD[id].geoJSON, {
				style: function (feature){
					msoa = feature.properties['msoa11cd'];
					v = _obj.scores[msoa].total||0;
					return {
						"color": "#2254F4",
						"weight": 0.4,
						"opacity": 0.5,
						"fillOpacity": v
					}
				},
				onEachFeature: function(feature, layer) {
					var popupContent = '<h2>'+feature.properties.msoa11hclnm+'</h2>';
					if(feature.properties && feature.properties.popupContent) popupContent += feature.properties.popupContent;
					layer.bindPopup(popupContent);
				}
			}).addTo(this.map);
			
			this.map.fitBounds(this.LADlayer.getBounds());
		}else{
			this.log.error('No GeoJSON for '+id);
		}
	};





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