// Run with playwright-cli -s=flow-review run-code --filename=dev-design/flow-review/export_pdf.js
async (page) => {
  await page.reload();
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.images].map(image => image.decode()));
    document.body.classList.remove('notes-off', 'ui-off');
  });
  await page.pdf({
    path: 'D:/recoil-requiem/dev-design/flow-review/反冲挽歌_完整流程设计.pdf',
    preferCSSPageSize: true,
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: '<span></span>',
    footerTemplate: '<div style="font-size:8px;color:#777;width:100%;text-align:center">RECOIL REQUIEM · FLOW REVIEW　<span class="pageNumber"></span> / <span class="totalPages"></span></div>'
  });
}
