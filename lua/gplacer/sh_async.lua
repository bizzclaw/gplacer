ASYNC = ASYNC or {
	Threads = {}
}

function async(callback)
	local thread = coroutine.create(callback)
	table.insert(ASYNC.Threads, thread)
	return thread
end

hook.Add("Think", "AsyncTick", function()
	for id, thread in pairs(ASYNC.Threads) do
		local ok, output = coroutine.resume(thread)
		if ok == false then
			ErrorNoHalt(" Error: ", output, "\n" )
			debug.Trace()
			table.remove(ASYNC.Threads, id)
		elseif coroutine.status( thread ) == "dead" then
			table.remove(ASYNC.Threads, id)
		end
	end
end)