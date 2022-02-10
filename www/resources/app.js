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
	function getIcon(icon,colour,cls){
		if(icons[icon]) return icons[icon].replace(/%COLOR%/g,(colour||"black")).replace(/%CLASS%/g,(cls||""));
		else return icon.marker.replace(/%COLOR%/g,(colour||"black")).replace(/%CLASS%/g,(cls||""));
	}
	var icons = {
		'loader':'<svg version="1.1" width="64" height="64" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg"><g transform="matrix(.11601 0 0 .11601 -49.537 -39.959)"><path d="m610.92 896.12m183.9-106.17-183.9-106.17-183.9 106.17v212.35l183.9 106.17 183.9-106.17z" fill="black"><animate attributeName="opacity" values="1;0;0" keyTimes="0;0.7;1" dur="1s" begin="-0.83333s" repeatCount="indefinite" /></path><path d="m794.82 577.6m183.9-106.17-183.9-106.17-183.9 106.17v212.35l183.9 106.17 183.9-106.17z" fill="black"><animate attributeName="opacity" values="1;0;0" keyTimes="0;0.7;1" dur="1s" begin="-0.6666s" repeatCount="indefinite" /></path><path d="m1162.6 577.6m183.9-106.17-183.9-106.17-183.9 106.17v212.35l183.9 106.17 183.9-106.17z" fill="black"><animate attributeName="opacity" values="1;0;0" keyTimes="0;0.7;1" dur="1s" begin="-0.5s" repeatCount="indefinite" /></path><path d="m1346.5 896.12m183.9-106.17-183.9-106.17-183.9 106.17v212.35l183.9 106.17 183.9-106.17z" fill="black"><animate attributeName="opacity" values="1;0;0" keyTimes="0;0.7;1" dur="1s" begin="-0.3333s" repeatCount="indefinite" /></path><path d="m1162.6 1214.6m183.9-106.17-183.9-106.17-183.9 106.17v212.35l183.9 106.17 183.9-106.17z" fill="black"><animate attributeName="opacity" values="1;0;0" keyTimes="0;0.7;1" dur="1s" begin="-0.1666s" repeatCount="indefinite" /></path><path d="m794.82 1214.6m183.9-106.17-183.9-106.17-183.9 106.17v212.35l183.9 106.17 183.9-106.17z" fill="black"><animate attributeName="opacity" values="1;0;0" keyTimes="0;0.7;1" dur="1s" begin="0s" repeatCount="indefinite" /></path></g></svg>',
		'geo':'<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><path style="fill:%COLOR%" d="M 16,0 L30,30 0,16 12,12 Z" /></svg>',
		'marker':'<svg xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" width="7.0556mm" height="11.571mm" viewBox="0 0 25 41.001" id="svg2" version="1.1"><g id="layer1" transform="translate(1195.4,216.71)"><path style="fill:%COLOR%;fill-opacity:1;fill-rule:evenodd;stroke:#ffffff;stroke-width:0.1;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none" d="M 12.5 0.5 A 12 12 0 0 0 0.5 12.5 A 12 12 0 0 0 1.8047 17.939 L 1.8008 17.939 L 12.5 40.998 L 23.199 17.939 L 23.182 17.939 A 12 12 0 0 0 24.5 12.5 A 12 12 0 0 0 12.5 0.5 z " transform="matrix(1,0,0,1,-1195.4,-216.71)" id="path4147" /><ellipse style="opacity:1;fill:#ffffff;fill-opacity:1;stroke:none;stroke-width:1.428;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1" id="path4173" cx="-1182.9" cy="-204.47" rx="5.3848" ry="5.0002" /></g></svg>',
		'ev':'<svg width="7.0556mm" height="11.571mm" version="1.1" viewBox="0 0 25 41.001" xmlns="http://www.w3.org/2000/svg"><path d="m12.5 0.5a12 12 0 0 0-12 12 12 12 0 0 0 1.3047 5.439h-0.0039l10.699 23.059 10.699-23.059h-0.017a12 12 0 0 0 1.318-5.439 12 12 0 0 0-12-12z" fill="%COLOR%" class="%CLASS%"/><path transform="matrix(.93753 0 0 .93753 -.00050402 0)" d="m10.441 6.4473c-0.554 0-1 0.446-1 1v3.6328h-1.9453v6.5625c0 1.108 0.892 2 2 2h2.3633v5.375h2.9648v-5.375h2.3457c1.108 0 2-0.892 2-2v-6.5625h-1.9453v-3.6328c0-0.554-0.446-1-1-1h-0.96484c-0.554 0-1 0.446-1 1v3.6328h-1.8535v-3.6328c0-0.554-0.446-1-1-1z" fill="white" /></svg>'
	}
	var evcolours = {
		'S': '#efd463',
		'F': '#00a3da',
		'R': '#d772da'
	}

	function EV(opts){
		this.name = "EV";
		this.version = "0.1";
		if(!opts) opts = {};
		this.log = new Logger({'id':this.name,'logging':(location.search.indexOf("logging=true")>=0)});
		var el = opts.el||document.getElementById('map');
		if(!el){
			this.log.error('No element found to attach map to');
			return this;
		}
		load = document.createElement('div');
		load.classList.add('loader');
		load.innerHTML = icons.loader;
		el.appendChild(load);
		this.mapper = new OSMMap(el);
		
		var _obj = this;

		this.maplayers = {
			'ev':{
				'file':'data/chargepoints.csv',
				'icon': 'ev',
				'parserow': function(col){
					var speeds = {'S':parseInt(col[3])||0,'F':parseInt(col[4])||0,'R':parseInt(col[5])||0};
					var ordered = Object.keys(speeds).sort(function(a,b){return speeds[a]-speeds[b]});
					return {'id':col[0],'shortid':col[0],'latitude':parseFloat(col[1]),'longitude':parseFloat(col[2]),'background':evcolours[ordered[ordered.length-1]],'speeds':speeds};
				},
				'popupdata':'data/chargepoints/%ID%.json',
				'popupopen': function(e,opts){
					fetch(this.maplayers[opts.key].popupdata.replace(/\%ID\%/g,opts.id)).then(response => {
						if(!response.ok) throw new Error('Network response was not OK');
						return response.json();
					}).then(data => {
						var str = '<h3>'+data.name+'</h3>';
						str += '<p>ID: '+data.chargeDeviceID+'<br />';
						addr = (data.street ? data.street : '');
						addr += (data.town ? (addr ? ', ':'')+data.town : '');
						addr += (data.county ? (addr ? ', ':'')+data.county : '');
						addr += (data.postcode ? (addr ? ', ':'')+data.postcode : '');
						str += addr;
						if(data.deviceOwnerName) str += '<br />Owner: '+(data.deviceOwnerWebsite ? '<a href="'+data.deviceOwnerWebsite+'" target="_parent">'+data.deviceOwnerName+'</a>' : data.deviceOwnerName)+(data.deviceOwnerTelephoneNo ? ', Tel: '+data.deviceOwnerTelephoneNo : '');
						if(data.deviceControllerName) str += '<br />Controller: '+(data.deviceControllerWebsite ? '<a href="'+data.deviceControllerWebsite+'" target="_parent">'+data.deviceControllerName+'</a>' : data.deviceControllerName)+(data.deviceControllerTelephoneNo ? ', Tel: '+data.deviceControllerTelephoneNo : '');
						str += '</p>';
						var li = '';
						for(var c = 1; c <= 8; c++){
							if(data['connector'+c+'ID']){
								speed = "S";
								kW = parseFloat(data['connector'+c+'RatedOutputKW']);
								if(kW >= 7) speed = "F";
								if(kW > 30) speed = "R";
								li += '<li class="speed-'+speed+'">'+kW+'kW</li>';
							}
						}
						if(li) str += '<ul class="ev-connectors">'+li+'</ul>';
						if(data.dateUpdated) str += '<p class="footer">Last updated: '+data.dateUpdated+'</p>';
						
						e.popup.setContent(str);
						//e.popup.update();
					}).catch(error => {
						console.error('There has been a problem with your fetch operation:', error);
					});
					return true;
				},
				'clusterhtml': function(key,pins){
					var colours = {'S':0,'F':0,'R':0};
					var total = 0;
					for(var i = 0; i < pins.length; i++){
						for(var s in _obj.maplayers[key].data[pins[i].props.m].speeds){
							colours[s] += _obj.maplayers[key].data[pins[i].props.m].speeds[s];
							total += _obj.maplayers[key].data[pins[i].props.m].speeds[s];
						}
					}
					var grad = "";
					// The number of colours
					var n = 0;
					var p = 0;
					for(var s in colours){
						if(grad) grad += ', ';
						grad += evcolours[s]+' '+Math.round(p)+'%';
						p += (100*colours[s]/total);
						grad += ' '+Math.round(p)+'%';
					}
					return '<div class="marker-group"><div class="marker-group-head" style="background:linear-gradient(to right, '+grad+');color:black;"></div><span>'+pins.length+'</span></div>';
				}
			}
		};
		this.loadFile('ev',this.addMarkers);

		return this;
	}
	
	EV.prototype.loadFile = function(key,cb){

		var _obj = this;
		
		fetch(this.maplayers[key].file).then(response => {
			if(!response.ok) throw new Error('Network response was not OK');
			return response.text();
		}).then(txt => {
			lines = txt.split(/\n/);
			rows = [];
			for(var r = 1; r < lines.length; r++){
				row = lines[r].split(/\,/);
				if(row[0]) rows.push(_obj.maplayers[key].parserow.call(_obj,row)||{'id':row[0]});
			}
			this.maplayers[key].data = rows;
			if(typeof cb==="function") cb.call(_obj,key);
		}).catch(error => {
			console.error('There has been a problem with your fetch operation:', error);
		});

		return this;
	}
	EV.prototype.addMarkers = function(key){

		this.mapper.buildMarkerLayer(key,this.maplayers[key].data,{
			'icon':this.maplayers[key].icon,
			'popupopen':this.maplayers[key].popupopen,
			'clusterhtml': this.maplayers[key].clusterhtml,
			'this': this
		});

		return this;
	}



	function OSMMap(el,options){

		if(!options) options = {};
		baseMaps = {};
		if(options.baseMaps) baseMaps = options.baseMaps;
		else{
			// Default maps
			baseMaps['Greyscale'] = L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
				attribution: 'Tiles: &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
				subdomains: 'abcd',
				maxZoom: 19
			});
			baseMaps['Open Street Map'] = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
				maxZoom: 19,
				attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
			});
			baseMaps['CartoDB Voyager (no labels)'] = L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png', {
				attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
				subdomains: 'abcd',
				maxZoom: 19
			});
			baseMaps['CartoDB Voyager'] = L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
				attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
				subdomains: 'abcd',
				maxZoom: 19
			});
		}
		this.selectedLayer = "CartoDB Voyager";

		var lat = 53.79659;
		var lon = -1.53385;
		var d = 0.05;
		var bbox = [[lat-d, lon-d],[lat+d, lon+d]];
		this.show = options.show||{};
		
		this.map = L.map(el,{'layers':[baseMaps[this.selectedLayer]],'scrollWheelZoom':true,'editable': true,'zoomControl': true}).fitBounds(bbox);
		this.collection = {};
		this.tooltip = L.DomUtil.get('tooltip');
		this.log = new Logger({'id':'OSMMap','logging':options.logging});
		this.events = {};
		this.nodes = {};
		this.nodegroup = {};

		
		this.setMarker = function(m){
			this.marker = m;
			return this;
		}

		this.setMarkers = function(m){
			this.markers = m;
			return this;
		}
		
		this.changeLayer = function(id){
			this.log.message('changeLayer',id,baseMaps);
			if(baseMaps[id]){
				this.map.removeLayer(baseMaps[this.selectedLayer]);
				this.map.addLayer(baseMaps[id]);
				this.selectedLayer = id;
			}
		};
		this.getLayers = function(){
			var l = [];
			for(var id in baseMaps){
				l.push({'id':id,'url':baseMaps[id]._url});
			}
			return l;
		}
		this.getLayer = function(){
			return {'id':this.selectedLayer,'url':baseMaps[this.selectedLayer]._url};
		}

		this.map.attributionControl.setPrefix('Map').setPosition('bottomright');

		if(this.show.zoom){
			// Add zoom control with options
			L.control.zoom({
				 position:'topleft',
				 'zoomInText': getIcon('zoomin','black'),
				 'zoomOutText': getIcon('zoomout','black')
			}).addTo(this.map);
		}

		function makeMarker(icon,colour,cls){
			return L.divIcon({
				'className': '',
				'html':	getIcon(icon,colour,cls),
				'iconSize':	 [27, 44],
				'iconAnchor': [13, 44] ,
				'popupAnchor': [0, -44]
			});
		}

		var _obj = this;

		this.buildMarkerLayer = function(key,markers,opts){
			
			this.log.message('buildMarkerLayer',key,markers,opts);

			this.nodegroup[key] = [];

			// Loop over markers building them as necessary
			for(var m = 0; m < markers.length; m++) markers[m].icon = makeMarker(markers[m].svg||opts.icon||'marker',markers[m].background||'black');

			var id,t,str,markerList,color,customicon,nodes,taglist,p;


			// Define the custom background colour for the group
			color = 'white';

			nodes = L.markerClusterGroup({
				chunkedLoading: true,
				maxClusterRadius: 40,
				iconCreateFunction: function (cluster){
					var pins = cluster.getAllChildMarkers();
					var html = (typeof opts.clusterhtml==="function") ? opts.clusterhtml.call(opts.this,key,pins) : '<div class="marker-group" style="background:black;color:white;">'+pins.length+'</div>';
					
					return L.divIcon({ html: html, className: '',iconSize: L.point(40, 40) });
				},
				// Disable all of the defaults:
				spiderfyOnMaxZoom: true,
				showCoverageOnHover: false,
				zoomToBoundsOnClick: true
			});

			// Remove the previous cluster group
			if(this.nodegroup[key]) this.map.removeLayer(this.nodegroup[key]);

			// Build marker list
			markerList = [];

			for(var m = 0; m < markers.length; m++){
				if(markers[m] && typeof markers[m].longitude==="number" && typeof markers[m].latitude==="number"){

					if(markers[m].longitude!==NaN && markers[m].latitude!==NaN){
						try {
							marker = L.marker([markers[m].latitude,markers[m].longitude],{'icon':markers[m].icon,'properties':{'m':m,'id':markers[m].id,'key':key,'class':markers[m].class}}).on('popupopen', function(e,l){
								_obj.trigger('popupopen',e);
								if(typeof opts.popupopen==="function") opts.popupopen.call(opts['this']||this,e,this.options.properties);
							}).on('popupclose',function(e){
								_obj.trigger('popupclose',e);
								if(typeof opts.popupclose==="function") opts.popupclose.call(opts['this']||this,e,this.options.properties);
							});						
							marker.props = {'m':m,'id':markers[m].shortid};
						}catch(err){
							console.error(err,m,markers[m]);
						}

						if(!marker.properties) marker.properties = {};
						marker.properties.background = (markers[m] ? markers[m].background : "black");
						marker.bindPopup('<h3>'+(markers[m].id||"Node")+'</h3>',{'icon':markers[m].icon});
						markerList.push(marker);
						
					}else{
						console.warn('Warning',m,markers[m]);
					}
				}else{
					this.log.warning('Unable to add node: '+id);
				}
			}

			// Add all the markers we've just made
			nodes.addLayers(markerList);
			this.map.addLayer(nodes);

			// Save a copy of the cluster group
			this.nodegroup[key] = nodes;
		}

		// Add geolocation control and interaction
		var geolocation = new GeoLocation({mapper:this});

		// Convert metres to pixels (used by GeoLocation)
		this.m2px = function(m,lat,zoom){
			if(!lat) lat = this.map.getCenter().lat;
			if(!zoom) zoom = this.map.getZoom();
			var mperpx = 40075016.686 * Math.abs(Math.cos(lat * 180/Math.PI)) / Math.pow(2, zoom+8);
			return m/mperpx;
		}

		this.on('moveend',function(){
			if(_obj.map.getZoom() >= 11){
				//_obj.getNodes(_obj.node.type,_obj.nodegetter._options);
			}
		});

		this.map.on("movestart", function(){ _obj.trigger('movestart'); });
		this.map.on("move", function(){ _obj.trigger('move'); });
		this.map.on("moveend", function(){ _obj.trigger('moveend'); });

		return this;
	}
			
	// Attach a handler to an event for the OSMEditor object in a style similar to that used by jQuery
	//   .on(eventType[,eventData],handler(eventObject));
	//   .on("authenticate",function(e){ console.log(e); });
	//   .on("authenticate",{me:this},function(e){ console.log(e.data.me); });
	OSMMap.prototype.on = function(ev,e,fn){
		if(typeof ev!="string") return this;
		if(is(fn,"undefined")){
			fn = e;
			e = {};
		}else{
			e = {data:e}
		}
		if(typeof e!="object" || typeof fn!="function") return this;
		if(this.events[ev]) this.events[ev].push({e:e,fn:fn});
		else this.events[ev] = [{e:e,fn:fn}];
		return this;
	}

	// Trigger a defined event with arguments. This is for internal-use to be 
	// sure to include the correct arguments for a particular event
	OSMMap.prototype.trigger = function(ev,args){
		if(typeof ev != "string") return;
		if(typeof args != "object") args = {};
		var o = [];
		if(typeof this.events[ev]=="object"){
			for(var i = 0 ; i < this.events[ev].length ; i++){
				var e = extendObject(this.events[ev][i].e,args);
				if(typeof this.events[ev][i].fn == "function") o.push(this.events[ev][i].fn.call(e['this']||this,e))
			}
		}
		if(o.length > 0) return o;
	}

	function hasClass(el,cls){
		for(var i = 0; i < el.classList.length; i++){
			if(el.classList[i] == cls) return true;
		}
		return false;
	}

	// Define a function to get user location
	function GeoLocation(options){
		if(!options) options = {};
		if(!options.mapper) return {};
		this.locating = false;
		this.log = new Logger({'id':'GeoLocation','logging':options.mapper.log.logging});

		var _obj = this;

		this.setLocation = function(p){

			var btn = document.getElementsByClassName('leaflet-control-geolocate')[0];
			this.log.message('setLocation',p,btn,hasClass(btn,'live-location'));

			if(!this.locating){
				this.p = null;
				navigator.geolocation.clearWatch(this.watchID);
				btn.classList.remove('live-location');
				this.marker.remove();
				this.marker = null;
				clearTimeout(this.check);
				return;
			}

			lat = p.coords.latitude;
			lon = p.coords.longitude;
			this.p = p;
			var a = Math.round(2*options.mapper.m2px(p.coords.accuracy,lat));

			btn.classList.add('live-location');
			if(!this.marker){
				var s = 10;
				var ico = L.divIcon({ html: '<div class="my-location-accuracy" style="width:'+a+'px;height:'+a+'px"></div>', 'className':'my-location', 'iconSize': L.point(s, s) });
				this.marker = L.marker([lat, lon],{icon:ico});
				this.marker.addTo(options.mapper.map);
				var _obj = this;
				options.mapper.map.on('zoomend', function() {
					_obj.setLocation(_obj.p,false);
				});
			}else{
				this.marker.setLatLng([lat, lon]).update();
				var el = document.querySelector('.my-location-accuracy');
				if(el){
					el.style.width = a+'px';
					el.style.height = a+'px';
				}
			}

			if(!this.centred){
				// We want to centre the view and update the nodes
				options.mapper.map.panTo(new L.LatLng(lat, lon))
//				options.mapper.getNodes(options.mapper.node.type,options.mapper.node.options);
				this.centred = true;
			}
			options.mapper.trigger('geoend',{'this':this});

		}

		if("geolocation" in navigator){

			// We need a function that checks how live the position is
			// that runs independently of the geolocation api
			this.updateLive = function(){
				console.log('GeoLocation check',this.p);
				if(this.p){
					var ago = ((new Date())-this.p.timestamp)/1000;
					if(ago > 10) document.getElementsByClassName('leaflet-control-geolocate')[0].classList.remove('live-location');
				}
			}

			var _obj = this;

			this.control = L.Control.extend({
				"options": { position: 'topleft' },
				"onAdd": function (map){

					_obj.log.message('control onAdd',map)

					var container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-geolocate');
					container.innerHTML = '<a href="#">'+getIcon('geo','black')+'</a>';
					container.onclick = function(e){

						e.preventDefault();
						_obj.centred = false;
						_obj.locating = !_obj.locating;

						if(_obj.locating){
							options.mapper.trigger('geostart',{'this':this});
							//if(options.mapper.callbacks && options.mapper.callbacks.geostart) options.mapper.callbacks.geostart.call(this);

							// Start watching the user location
							_obj.watchID = navigator.geolocation.watchPosition(function(position){
								_obj.setLocation(position);
							},function(){
								_obj.log.error("Sorry, no position available.");
							},{
								enableHighAccuracy: true, 
								maximumAge		: 30000, 
								timeout		   : 27000
							});

							// Create a checker to see if the geolocation is live
							_obj.check = setInterval(function(){ _obj.updateLive(); },10000);

						}else{

							_obj.setLocation();

						}
					}
					return container;
				}
			});

			options.mapper.map.addControl(new _obj.control());

		}else{

			this.log.warning('No location services available');

		}

		return this;
	}

	function Tiler(){
		var R = 6378137, sphericalScale = 0.5 / (Math.PI * R);

		function tile2lon(x,z){ return (x/Math.pow(2,z)*360-180); }
		function tile2lat(y,z){ var n=Math.PI-2*Math.PI*y/Math.pow(2,z); return (180/Math.PI*Math.atan(0.5*(Math.exp(n)-Math.exp(-n)))); }

		/* Adapted from: https://gist.github.com/mourner/8825883 */
		this.xyz = function(bounds, z) {

			var min = project(bounds._northEast.lat,bounds._southWest.lng, z);//north,west
			var max = project(bounds._southWest.lat,bounds._northEast.lng, z);//south,east
			var tiles = [];
			var x,y;
			for(x = min.x; x <= max.x; x++) {
				for(y = min.y; y <= max.y; y++) {
					tiles.push({
						x: x,
						y: y,
						z: z,
						b: {'_northEast':{'lat':tile2lat(y,z),'lng':tile2lon(x+1,z)},'_southWest':{'lat':tile2lat(y+1,z),'lng':tile2lon(x,z)}}
					});
				}
			}
			return tiles;
		}

		/* 
		Adapts a group of functions from Leaflet.js to work headlessly
		https://github.com/Leaflet/Leaflet
		*/
		function project(lat,lng,zoom) {
			var d = Math.PI / 180,
			max = 1 - 1E-15,
			sin = Math.max(Math.min(Math.sin(lat * d), max), -max),
			scale = 256 * Math.pow(2, zoom);

			var point = {
				x: R * lng * d,
				y: R * Math.log((1 + sin) / (1 - sin)) / 2
			};

			point.x = tiled(scale * (sphericalScale * point.x + 0.5));
			point.y = tiled(scale * (-sphericalScale * point.y + 0.5));

			return point;
		}

		function tiled(num) {
			return Math.floor(num/256);
		}
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
	
	root.OI.EV = function(opts){
		return new EV(opts);
	}
	root.Logger = Logger;

})(window || this);