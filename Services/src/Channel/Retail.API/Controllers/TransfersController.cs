using System;
using System.Net.Mime;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Retail.API.Commands;
using Quantic.Core;
using Quantic.Web;

namespace Retail.API.Controllers
{
    [ApiVersion("1.0")]
    [Route("api/v{v:apiVersion}")]
    [ApiController]
    public class TransfersController : BaseController
    {
        private readonly ICommandHandler<DoTransfer> doTransferHandler;

        public TransfersController(ICommandHandler<DoTransfer> doTransferHandler)
        {
            this.doTransferHandler = doTransferHandler;
        }

        [HttpPost("transfers")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Produces(MediaTypeNames.Application.Json)]
        [ProducesResponseType(StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(Error[]), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(Error[]), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(Error[]), StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> Create([FromBody] DoTransferRequest request)
        {
            var result = await doTransferHandler.Handle(new DoTransfer(request.Sender, request.Receiver, request.Amount, request.Currency), Context);
            return result.Ok();
        }
    }
}
