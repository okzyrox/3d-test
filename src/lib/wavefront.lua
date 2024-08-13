local wavefront={
	version="0.0.4"
}

local table_clear = table.clear or function(t)
	for i=#t,1,-1 do
		t[i]=nil
	end
end

-------------------------------------------------------------------------------

function wavefront.import(obj_data,mtl_data)
	local vertices  = {}
	local normals   = {}
	local textures  = {}
	local materials = {}
	local faces     = {}
	
	local tokens={}
	
	if mtl_data then
		local cm
		
		for line in (mtl_data.."\n"):gmatch("(.-)\n") do
			table_clear(tokens)
			
			for word in line:gmatch("%S+") do
				tokens[#tokens+1]=tonumber(word:lower()) or word
			end
			
			if tokens[1]=="newmtl" then
				cm=tokens[2]
				for i=3,#tokens do
					cm=cm.." "..tokens[i]
				end
				materials[cm]={}
			elseif tokens[1]=="map_Kd" then
				materials[cm].texture=tokens[2]
			end
		end
	end
	
	if obj_data then
		local cm=""
		
		for line in (obj_data.."\n"):gmatch("(.-)\n") do
			table_clear(tokens)
			
			for word in line:gmatch("%S+") do
				tokens[#tokens+1]=tonumber(word:lower()) or word
			end
			
			if tokens[1]=="v" then
				for i=2,#tokens do
					vertices[#vertices+1]=tokens[i]
				end
			elseif tokens[1]=="vn" then
				for i=2,#tokens do
					normals[#normals+1]=tokens[i]
				end
			elseif tokens[1]=="vt" then
				textures[#textures+1]=tokens[2]
				textures[#textures+1]=1-tokens[3]
			elseif tokens[1]=="f" then
				for i=2,#tokens do
					local v,vn,vt
					
					for n in tokens[i]:gmatch("([^/]+)") do
						if not v then
							v=tonumber(n)
						elseif not vt then
							vt=tonumber(n)
						elseif not vn then
							vn=tonumber(n)
						end
					end
					
					faces[#faces+1] = v
					faces[#faces+1] = vn
					faces[#faces+1] = vt
					--faces[#faces+1] = cm
				end
			elseif tokens[1]=="usemtl" then
				cm=tokens[2]
			end
		end
	end
	
	return {
		vertices  = vertices,
		normals   = normals,
		textures  = textures,
		materials = materials,
		faces     = faces
	}
end

function wavefront.export(vertices,normals,faces,textures)
	
end

-------------------------------------------------------------------------------

return wavefront