Model = require './model'

class Service extends Model

    url: -> "#{ config.apiRoot }/state/#{ @serviceId }?authkey=#{ config.authKey }"

    deleteTemplate: require '../templates/vex/serviceRemove'
    deleteSuccessTemplate: require '../templates/vex/serviceRemoveSuccess'
    removeUpstreamsTemplate: require '../templates/vex/removeUpstreams'
    removeUpstreamTemplate: require '../templates/vex/removeUpstream'
    removeUpstreamsSuccessTemplate: require '../templates/vex/removeUpstreamsSuccess'

    initialize: ({ @serviceId }) ->

    parse: (data) ->
        data.id = data.service.serviceId
        data.loadBalancerGroups = data.service.loadBalancerGroups
        data.splitLbGroups = utils.splitArray(data.service.loadBalancerGroups.sort(), Math.ceil(data.service.loadBalancerGroups.length/2))
        data.owners = data.service.owners
        data.splitOwners = utils.splitArray(data.service.owners.sort(), Math.ceil(data.service.owners.length/2))
        data.basePath = data.service.serviceBasePath
        data.options = data.service.options
        data.splitUpstreams = utils.splitArray(data.upstreams, Math.ceil(data.upstreams.length/2))
        data.upstreamsCount = data.upstreams.length
        if data.upstreamsCount > 0
            data.active = true
        data

    delete: =>
        $.ajax
            url: @url()
            type: "DELETE"
            success: (data) =>
                console.dir(data)
                @set('request', data.loadBalancerRequestId)

    undo: =>
        this.fetch({
            success: =>
                requestId = @requestId()
                @set('request', requestId)
                serviceData = {
                    loadBalancerRequestId: requestId
                    loadBalancerService:
                        serviceId: @id
                        owners: if @attributes.owners then @attributes.owners else []
                        serviceBasePath: @attributes.basePath
                        loadBalancerGroups: @attributes.loadBalancerGroups
                    addUpstreams: []
                    removeUpstreams: @attributes.upstreams
                }
                $.ajax
                    url: "#{ config.apiRoot }/request?authkey=#{ config.authKey }"
                    type: "post"
                    contentType: "application/json"
                    data: JSON.stringify(serviceData)
        })

    remove: (upstream) =>
        this.fetch({
            success: =>
                requestId = @requestId()
                @set('request', requestId)
                serviceData = {
                    loadBalancerRequestId: requestId
                    loadBalancerService:
                        serviceId: @id
                        owners: if @attributes.owners then @attributes.owners else []
                        serviceBasePath: @attributes.basePath
                        loadBalancerGroups: @attributes.loadBalancerGroups
                        options: @attributes.options
                    addUpstreams: []
                    removeUpstreams: [{upstream: upstream, request: requestId}]
                }
                $.ajax
                    url: "#{ config.apiRoot }/request?authkey=#{ config.authKey }"
                    type: "post"
                    contentType: "application/json"
                    data: JSON.stringify(serviceData)
        })

    requestId: -> "#{@serviceId}-#{Date.now()}"


    promptDelete: (callback) =>
        vex.dialog.confirm
            message: @deleteTemplate {@serviceId}
            buttons: [
                $.extend {}, vex.dialog.buttons.YES,
                    text: 'DELETE',
                    className: 'vex-dialog-button-primary vex-dialog-button-primary-remove'
                vex.dialog.buttons.NO
            ]
            callback: (data) =>
                return if data is false
                @delete().done callback

    promptDeleteSuccess: (callback) =>
        vex.dialog.confirm
            message: @deleteSuccessTemplate {request: @get('request'), config: config}
            buttons: [
                $.extend {}, vex.dialog.buttons.YES,
                    text: 'OK',
                    className: 'vex-dialog-button-primary vex-dialog-button-primary-remove'
            ]
            callback: (data) =>
                return

    promptRemoveUpstreams: (callback) =>
        vex.dialog.confirm
            message: @removeUpstreamsTemplate {@serviceId}
            buttons: [
                $.extend {}, vex.dialog.buttons.YES,
                    text: 'REMOVE',
                    className: 'vex-dialog-button-primary vex-dialog-button-primary-remove'
                vex.dialog.buttons.NO
            ]
            callback: (data) =>
                return if data is false
                @undo().done callback

    promptRemoveUpstreamsSuccess: (callback) =>
        vex.dialog.confirm
            message: @removeUpstreamsSuccessTemplate {request: @get('request') config: config}
            buttons: [
                $.extend {}, vex.dialog.buttons.YES,
                    text: 'OK',
                    className: 'vex-dialog-button-primary vex-dialog-button-primary-remove'
            ]
            callback: (data) =>
                return

    promptRemoveUpstream: (upstream, callback) =>
        vex.dialog.confirm
            message: @removeUpstreamTemplate {upstream: upstream}
            buttons: [
                $.extend {}, vex.dialog.buttons.YES,
                    text: 'REMOVE',
                    className: 'vex-dialog-button-primary vex-dialog-button-primary-remove'
                vex.dialog.buttons.NO
            ]
            callback: (data) =>
                return if data is false
                @remove(upstream).done callback

module.exports = Service
