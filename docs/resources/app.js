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

	function EValuator(opts){

		this.name = "EValuator";
		this.version = "0.1";
		if(!opts) opts = {};

		this.log = new Logger({'id':this.name,'logging':(location.search.indexOf("logging=true")>=0)});

		this.arealookup = {};
		this.scores = {};
		this.area = "E08000035";
		
		this.el = {};
		this.el.map = opts.map||document.getElementById('map');
		this.el.ranking = opts.ranking||document.getElementById('ranking');
		this.el.weights = opts.weights||document.getElementById('weights');
		if(!this.el.map){
			this.log.error('No element found to attach map to');
			return this;
		}
		if(!this.el.ranking){
			this.log.error('No element found to attach ranking to');
			return this;
		}
		// Map
		var baseMaps = {
			'Greyscale': L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_nolabels/{z}/{x}/{y}.png', {
				attribution: 'Tiles: &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
				subdomains: 'abcd',
				maxZoom: 19
			})
		};

		var lat = 53.79659;
		var lon = -1.53385;
		var d = 4;
		var bbox = [[lat-d, lon-d],[lat+d, lon+d]];

		this.map = L.map(this.el.map,{'layers':[baseMaps["Greyscale"]],'scrollWheelZoom':true,'editable': true,'zoomControl': true}).fitBounds(bbox);


		// Create a map label pane so labels can sit above polygons
		this.map.createPane('labels');
		this.map.getPane('labels').style.zIndex = 650;
		this.map.getPane('labels').style.pointerEvents = 'none';
		L.tileLayer('https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png', {
			attribution: '',
			pane: 'labels'
		}).addTo(this.map);


		// Get the area lookup
		fetch('data/areas.tsv').then(response => {
			if(!response.ok) throw new Error('Network response was not OK');
			return response.text();
		}).then(data => {
			var lines = data.split(/\n/);
			lines.shift();
			for(var i = 0; i < lines.length; i++){
				if(lines[i][1]){
					lines[i] = lines[i].split(/\t/);
					if(lines[i].length == 2){
						this.arealookup[lines[i][0]] = {'name':lines[i][1]};
					}
				}
			}

			fetch("data/domains.json").then(response => {
				if(!response.ok) throw new Error('Network response was not OK');
				return response.json();
			}).then(data => {
				this.categories = data;
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
		var c,heading,desc,category,l,inp;

		this.input = document.getElementById('area');

		// Build the barchart object attached to <input type="text" id="area">
		this.typeahead = TypeAhead.init(this.input,{
			'items': obj2arr(this.arealookup),
			'process': function(d){ _obj.setArea(d.id); },
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

		// Sliders
		this.sliders = {};
		for(c = 0; c < this.categories.length; c++){
			heading = document.createElement('h3');
			heading.innerHTML = this.categories[c].title;
			this.el.weights.appendChild(heading);

			if(this.categories[c].desc){
				desc = document.createElement('p');
				desc.innerHTML = this.categories[c].desc;
				this.el.weights.appendChild(desc);
			}
			category = document.createElement('div');
			category.classList.add('category');
			for(l = 0; l < this.categories[c].layers.length; l++){
				inp = new Slider({
					'id':this.categories[c].layers[l].id,
					'label':this.categories[c].layers[l].title,
					'desc':this.categories[c].layers[l].desc,
					'class':'slider',
					'data': {'layer':this.categories[c].layers[l].id,'category':c},
					'invert': this.categories[c].layers[l].invert,
					'value': this.categories[c].layers[l].weight||1,
					'onchange':function(e){
						_obj.updateLayer(e.data.layer,e.data.value,e.data.invert);
						_obj.postArea();
					}
				});
				inp.addTo(category);
				this.sliders[this.categories[c].layers[l].id] = inp;
			}
			this.el.weights.appendChild(category);
		}



		// Get presets
		fetch('data/presets.json').then(response => {
			if(!response.ok) throw new Error('Network response was not OK');
			return response.json();
		}).then(data => {

			// Add default values as first element of array
			var def = {"title":"Default","weights":{}};
			var c,l;
			for(c = 0; c < this.categories.length; c++){
				for(l = 0; l < this.categories[c].layers.length; l++){
					def.weights[this.categories[c].layers[l].id] = {"value":this.categories[c].layers[l].weight,"invert":this.categories[c].layers[l].invert||false};
				}
			}
			data.unshift(def);

			this.el.presets = document.createElement('div');
			this.el.presets.id = "presets";
			this.el.weights.insertBefore(this.el.presets, this.el.weights.firstChild);

			// Add presets here
			if(this.el.presets){
				this.el.presets.innerHTML = "";
				var i,btns,btn,_obj;
				btns = [];
				_obj = this;
				if(data.length){
					var h = document.createElement('h2');
					h.innerHTML = "Presets";
					this.el.presets.appendChild(h);
				}
				for(i = 0; i < data.length; i++){
					btn = document.createElement('button');
					btn.innerHTML = data[i].title||"?";
					btn.setAttribute('data',i);
					btn.addEventListener('click',function(e){
						var i,s;
						s = document.querySelectorAll('button.selected');
						for(i = 0; i < s.length; i++) s[i].classList.remove('selected');
						e.target.classList.add('selected');
						i = parseInt(e.target.getAttribute('data'));
						_obj.setWeights(data[i].weights);
					});
					this.el.presets.appendChild(btn);
					btns[i] = btn;
				}
			}
		}).catch(error => {
			console.error('There has been a problem with your fetch operation:', error);
		});
		return this;
	};
	
	EValuator.prototype.setWeights = function(weights){
		var weight,w,inv;
		for(weight in this.sliders){
			w = 0;
			inv = false;
			if(weights[weight]){
				if(typeof weights[weight].value==="number") w = weights[weight].value;
				if(typeof weights[weight].invert==="boolean") inv = weights[weight].invert;
			}
			this.sliders[weight].setValue(w);
			this.sliders[weight].setInvert(inv);
			this.updateLayer(weight,w,inv);
		}
		this.postArea();
		return this;
	};

	EValuator.prototype.updateLayer = function(lay,w,inv){
		var c,l;
		if(typeof w!=="number") w = 0;
		if(typeof inv!=="boolean") inv = false;
		for(c in this.categories){
			for(l = 0; l < this.categories[c].layers.length; l++){
				if(this.categories[c].layers[l].id==lay){
					this.categories[c].layers[l].weight = w;
					this.categories[c].layers[l].invert = inv;
				}
			}
		}
		return this;
	};

	EValuator.prototype.setArea = function(id){
		if(id && this.arealookup[id]){
			if(!this.arealookup[id].MSOA){

				fetch('data/areas/'+id+'/'+id+'.csv').then(response => {
					if(!response.ok) throw new Error('Network response was not OK');
					return response.text();
				}).then(data => {
					var lines = data.split(/\n/);
					this.arealookup[id].MSOA = {};
					var header = lines[0].replace(/\r/g,'').split(/,/);
					var i,h;
					for(i = 1; i < lines.length; i++){
						if(lines[i][1]){
							lines[i] = lines[i].split(/\,/);
							this.arealookup[id].MSOA[lines[i][0]] = {'name':lines[i][1].replace(/(^\"|\"$)/g,"")};
							for(h = 2; h < header.length; h++){
								if(!this.scores[lines[i][0]]) this.scores[lines[i][0]] = {};
								this.scores[lines[i][0]][header[h]] = parseFloat(lines[i][h]);
							}
						}
					}
					this.postArea(id);
				}).catch(error => {
					console.error('There has been a problem with your fetch operation:', error);
				});


			}else{
				this.log.info('Already loaded MSOAs for '+id);
				this.postArea(id);
			}
		}
	};
	
	EValuator.prototype.postArea = function(id){
		
		if(!id) id = this.area;
		var c,l,msoa,min,max,a,v,weight,credits,t;

		if(!this.arealookup[id].MSOA){
			this.log.warning('No MSOAs defined for '+this.arealookup[id].name+' ('+id+')');
			return this;
		}

		this.area = id;

		// Update the input field
		this.input.setAttribute('placeholder',this.arealookup[id].name);
		this.input.value = "";

		// Find the min/max for each layers
		for(c = 0; c < this.categories.length; c++){
			for(l = 0; l < this.categories[c].layers.length; l++){
				min = 1e100;
				max = -1e100;
				// Loop over the MSOAs in this area
				for(msoa in this.arealookup[id].MSOA){
					if(typeof this.scores[msoa][this.categories[c].layers[l].id]==="number"){
						min = Math.min(this.scores[msoa][this.categories[c].layers[l].id],min);
						max = Math.max(this.scores[msoa][this.categories[c].layers[l].id],max);
					}else{
						this.log.warning('No score for '+this.categories[c].layers[l].id+' for '+msoa);
					}
				}
				this.categories[c].layers[l].min = min;
				this.categories[c].layers[l].max = max;
				this.categories[c].layers[l].range = max - min;
				if(typeof this.categories[c].layers[l].weight!=="number") this.categories[c].layers[l].weight = 1;
			}
		}

		this.attribution = "";
		credits = {};
		for(c = 0; c < this.categories.length; c++){
			for(l = 0; l < this.categories[c].layers.length; l++){
				if(this.categories[c].layers[l].weight > 0){
					if(this.categories[c].layers[l].attrib){
						for(a = 0; a < this.categories[c].layers[l].attrib.length; a++){
							credits[this.categories[c].layers[l].attrib[a]] = 1;
						}
					}
				}
			}
		}
		for(c in credits) this.attribution += (this.attribution ? ', ':'')+c;


		weight = 0;
		for(c = 0; c < this.categories.length; c++){
			for(l = 0; l < this.categories[c].layers.length; l++){
				if(this.categories[c].layers[l].range > 0) weight += this.categories[c].layers[l].weight;
			}
		}

		for(msoa in this.arealookup[id].MSOA){
			this.scores[msoa].total = 0;
			// Avoid divide-by-zero errors
			if(weight > 0){
				for(c = 0; c < this.categories.length; c++){
					for(l = 0; l < this.categories[c].layers.length; l++){
						// Only include if the range for this layer is non-zero
						if(this.categories[c].layers[l].range > 0){
							v = (this.scores[msoa][this.categories[c].layers[l].id] - this.categories[c].layers[l].min)/this.categories[c].layers[l].range;
							this.scores[msoa].total += (this.categories[c].layers[l].weight)*(this.categories[c].layers[l].invert ? (1 - v) : v);
						}
					}
				}
				this.scores[msoa].total = this.scores[msoa].total/weight;
			}
		}


		var totals = [];
		for(msoa in this.arealookup[this.area].MSOA) totals.push([msoa,this.scores[msoa].total,this.arealookup[this.area].MSOA[msoa].name]);
		totals.sort(function(a,b){
			if(b[1] == a[1]) return a[2].localeCompare(b[2]);
			else return b[1] - a[1];
		});

		var list = '<tr><th></th><th>MSOA</th><th>Name</th>';
		for(c = 0; c < this.categories.length; c++){
			for(l = 0; l < this.categories[c].layers.length; l++){
				list += '<th><div><span>'+this.categories[c].layers[l].title+'</span></div></th>';
			}
		}
		list += '<th>Score</th>';
		list += '</tr>';
		for(t = 0; t < totals.length; t++){
			msoa = totals[t][0];
			list += '<tr data="'+msoa+'"><td class="num">'+(t+1)+'</td>';
			list += '<td>'+msoa+'</td>';
			list += '<td>'+this.arealookup[this.area].MSOA[msoa].name+'</td>';
			for(c = 0; c < this.categories.length; c++){
				for(l = 0; l < this.categories[c].layers.length; l++){
					list += '<td class="num">'+this.scores[msoa][this.categories[c].layers[l].id]+'</td>';
				}
			}
			list += '<td class="num">'+this.scores[msoa].total.toFixed(2)+'</td>';
			list += '</tr>';
		}
		if(!this.el.ranking){
			this.el.ranking = document.createElement('ul');
			this.el.ranking.id = 'MSOAs';
			this.el.map.insertAdjacentElement('afterend', this.el.ranking);
		}
		this.el.ranking.innerHTML = '<div class="table-wrapper"><table>'+list+'</table></div>';
		
		var trs = this.el.ranking.querySelectorAll('tr');
		var _obj = this;
		for(t = 0; t < trs.length; t++){
			trs[t].addEventListener('click',function(e){
				var tr = e.target.closest('tr');
				var msoa = tr.getAttribute('data');
				location.href = "model.html?area="+_obj.area+"&msoa="+msoa;
			});
		}

		if(!this.arealookup[id].geoJSON){
			fetch('data/areas/'+id+'/'+id+'.geojson').then(response => {
				if(!response.ok) throw new Error('Network response was not OK');
				return response.json();
			}).then(data => {
				this.arealookup[id].geoJSON = data;
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
		
		if(this.arealookup[id].geoJSON){
			if(this.arealayer) this.map.removeLayer(this.arealayer);

			var _obj = this;
			this.arealayer = L.geoJSON(this.arealookup[id].geoJSON, {
				style: function (feature){
					var msoa = feature.properties.msoa11cd;
					// Scale the opacity to the range 0.1 - 0.8 so that we can still see some map
					var v = (_obj.scores[msoa].total||0)*0.7 + 0.1;
					return {
						"color": "#2254F4",
						"weight": 0.6,
						"opacity":0.3,
						"fillOpacity": v
					};
				},
				onEachFeature: function(feature, layer) {
					var popupContent = '<h3>'+feature.properties.msoa11hclnm+'</h3>';
					if(feature.properties && feature.properties.popupContent) popupContent += feature.properties.popupContent;
					layer.bindPopup(popupContent);
				}
			}).addTo(this.map);
			
			this.map.attributionControl.setPrefix('<span class="AttributionClass">Data: '+this.attribution+' | <a href=\"https://geoportal.statistics.gov.uk/datasets/middle-layer-super-output-areas-december-2011-boundaries-ew-bgc\">Boundaries</a>: ONS (Contains OS data © Crown copyright and database right 2021).</span>');
			
			this.map.fitBounds(this.arealayer.getBounds());
		}else{
			this.log.error('No GeoJSON for '+id);
		}
	};


	function Slider(opt){
		if(!opt) opt = {};
		var inp,inv,lbl,invlbl,val,cls,desc,info,span,_obj;

		_obj = this;

		cls = opt.class||'slider';

		if(opt.label){
			lbl = document.createElement('label');
			lbl.innerHTML = opt.label;
			if(opt.id) lbl.setAttribute('for',opt.id);
		}

		val = document.createElement('div');
		val.classList.add('value');

		inp = document.createElement('input');
		inp.setAttribute('type','range');
		inp.setAttribute('min',opt.min||0);
		inp.setAttribute('max',opt.max||1);
		inp.setAttribute('step',opt.step||0.1);
		if(opt.id) inp.setAttribute('id',opt.id);
		if(opt.vertical){
			inp.setAttribute('orient','vertical');
			inp.setAttribute('style','writing-mode: bt-lr;-webkit-appearance: slider-vertical;');
		}
		inp.addEventListener('input',function(e){
			var fn = function(e){ _obj.updateValue(inp.value); };
			if(typeof opt.onchange==="function") fn = opt.onchange;
			if(opt.data) e.data = opt.data;
			e.data.value = parseFloat(inp.value);
			_obj.updateValue(e.data.value);
			e.data.invert = inv.checked;
			// Call the callback function
			fn.call(_obj,e);
		});
		

		inv = document.createElement('input');
		inv.setAttribute('type','checkbox');
		if(typeof opt.invert==="boolean" && opt.invert) inv.setAttribute('checked','checked');
		if(opt.id) inv.setAttribute('id',opt.id+'-invert');
		inv.addEventListener('click',function(e){
			var event = document.createEvent('HTMLEvents');
			event.initEvent('input', true, false);
			inp.dispatchEvent(event);
		});

		invlbl = document.createElement('label');
		invlbl.classList.add('checkbox-label');
		invlbl.innerHTML = '<span>Inverted</span>';
		if(opt.label) invlbl.setAttribute('title','Invert '+opt.label);
		invlbl.classList.add('invert');
		if(opt.id) invlbl.setAttribute('for',opt.id+'-invert');
		span = document.createElement('span');
		span.classList.add('checkbox-custom','circular');
		invlbl.insertBefore(inv, invlbl.firstChild);
		inv.insertAdjacentElement('afterend', span);
		

		desc = document.createElement('div');
		desc.classList.add('more-info');
		desc.innerHTML = opt.desc||"";
		desc.style.display = 'none';
		info = document.createElement('button');
		info.classList.add('info');
		info.setAttribute('title',(opt.desc||"").replace(/<[^\>]*>/g,''));
		info.addEventListener('click',function(e){
			var els = document.querySelectorAll('.more-info');
			var el = e.target.querySelector('.more-info');
			for(var i = 0; i < els.length; i++){
				if(els[i] == el){
					if(el.style.display) el.style.display = '';
					else el.style.display = 'none';
				}else{
					els[i].style.display = 'none';
				}
			}
				console.log(e.target.parentNode.querySelector('.more-info'));
		});
		lbl.appendChild(info);
		info.appendChild(desc);
		
		
		this.addTo = function(el){
			el.appendChild(lbl);
			el.appendChild(inp);
			el.appendChild(val);
			el.appendChild(invlbl);
			
			// Trigger the change event when we first add it
			var event = document.createEvent('HTMLEvents');
			event.initEvent('change', true, false);
			el.dispatchEvent(event);
			return this;
		};
		this.setValue = function(v){
			inp.setAttribute('value',v);
			this.updateValue(v);
		};
		this.updateValue = function(txt){
			val.innerHTML = parseFloat(txt).toFixed(1);
			return this;
		};
		this.setInvert = function(state){
			// Set the state
			if(typeof state!=="boolean") state = false;
			inv.checked = state;
			return this;
		};
		this.setValue(opt.value||1);
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
	Logger.prototype.message = function(){ this.log('MESSAGE',arguments); };
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
	};
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
	};
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
		};
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
		this.clearItems = function(){ items = []; };
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